;;; lisp/llm-tools.el -*- lexical-binding: t; -*-

;; Tools let the local model look around on its own. Reading never asks;
;; writing asks before every call (gptel's `:confirm'). Because reading never
;; asks, a prompt injected into any file or note the model reads could ask
;; for credentials, so no tool touches remote files or the paths below.
(defconst my/gptel-tool-max-chars 32000
  "Cap on text a tool returns, ~8k tokens: half the 16k context window.")

(defconst my/gptel-tool-denied-paths
  '("~/.ssh/" "~/.gnupg/" "~/.password-store/" "~/.aws/"
    "~/.config/llama-server/" "~/.extra_config" "~/.authinfo" "~/.netrc")
  "Files, and directories (ending in /), that the tools refuse.
They hold keys and credentials.")

(defconst my/gptel-tool-denied-regexp "\\.\\(gpg\\|age\\)\\'"
  "File names the tools refuse: encrypted files.
Emacs decrypts .gpg files as it reads them when gpg-agent has the
passphrase cached, so the model would get the plaintext.")

(defun my/gptel-tool-denied-p (file)
  "Non-nil if FILE, an absolute local path, is one the tools refuse.
Symlinks are resolved first, so a link into ~/.ssh is refused too."
  (let ((true (file-truename file)))
    (or (string-match-p my/gptel-tool-denied-regexp true)
        (seq-some (lambda (denied)
                    (let ((target (file-truename (expand-file-name denied))))
                      (if (directory-name-p denied)
                          (string-prefix-p (file-name-as-directory target)
                                           (file-name-as-directory true))
                        (string= target true))))
                  my/gptel-tool-denied-paths))))

(defun my/gptel-tool-path (path &optional root)
  "Expand PATH against ROOT, by default the project root or `default-directory'.
Signal an error for a remote path, since TRAMP would open a connection,
and for one `my/gptel-tool-denied-p' refuses."
  (let ((root (or root (doom-project-root) default-directory)))
    ;; Check before expanding: TRAMP connects to expand a remote ~.
    (when (or (file-remote-p path) (file-remote-p root))
      (error "Remote paths are off limits: %s" path))
    (let ((file (expand-file-name path root)))
      (when (my/gptel-tool-denied-p file)
        (error "%s holds credentials and is off limits" file))
      file)))

(defun my/gptel-tool-cap (text)
  "Return TEXT cut to `my/gptel-tool-max-chars', saying so when cut."
  (if (<= (length text) my/gptel-tool-max-chars)
      text
    (concat (substring text 0 my/gptel-tool-max-chars)
            (format "\n[cut off: showing the first %d of %d characters]"
                    my/gptel-tool-max-chars (length text)))))

(defun my/gptel-tool-safely (fn)
  "Wrap FN so an error comes back to the model as text it can react to.
Otherwise a missing file would abort the whole request."
  (lambda (&rest args)
    (condition-case err
        (apply fn args)
      (error (format "Error: %s" (error-message-string err))))))

(defun my/gptel-rg (pattern target &rest flags)
  "Search TARGET for PATTERN with ripgrep, adding FLAGS.
Return matches as path:line:text, capped by `my/gptel-tool-cap'."
  (with-temp-buffer
    (pcase (apply #'call-process "rg" nil t nil
                  ;; rg drops the path for a single file unless asked, so
                  ;; force path:line:text.
                  (append '("--with-filename" "--line-number" "--color=never"
                            "--max-columns=300")
                          flags (list "-e" pattern target)))
      (0 (my/gptel-tool-cap (buffer-string)))
      (1 (format "No matches for %s in %s" pattern target))
      (_ (format "Error: rg failed: %s" (buffer-string))))))

(after! gptel
  (setq gptel-tools
        (list
         (gptel-make-tool
          :name "read_file"
          :category "local"
          :description "Return the text of a file. Relative paths are resolved
against the current project root. Long files are cut off."
          :args '((:name "path" :type string
                   :description "Path of the file to read"))
          :function
          (my/gptel-tool-safely
           (lambda (path)
             (let ((file (my/gptel-tool-path path)))
               (with-temp-buffer
                 ;; No file handlers, so nothing gets decrypted, decompressed
                 ;; or fetched over the network, whatever the checks missed.
                 (let ((file-name-handler-alist nil))
                   (insert-file-contents file))
                 (my/gptel-tool-cap (buffer-string)))))))

         (gptel-make-tool
          :name "list_directory"
          :category "local"
          :description "List the entries of a directory, one per line;
directories end with /. Relative paths are resolved against the project root."
          :args '((:name "path" :type string
                   :description "Directory to list, e.g. \".\" for the project root"))
          :function
          (my/gptel-tool-safely
           (lambda (path)
             (let* ((dir (file-name-as-directory (my/gptel-tool-path path)))
                    (entries (directory-files
                              dir nil directory-files-no-dot-files-regexp)))
               (if (null entries)
                   (format "%s is empty" dir)
                 (mapconcat (lambda (f)
                              (if (file-directory-p (concat dir f))
                                  (concat f "/")
                                f))
                            entries "\n"))))))

         (gptel-make-tool
          :name "search_project"
          :category "local"
          :description "Search files for a regular expression with ripgrep and
return matching lines as path:line:text. Searches the project root unless a
path is given."
          :args '((:name "pattern" :type string
                   :description "Regular expression (ripgrep syntax)")
                  (:name "path" :type string :optional t
                   :description "Directory or file to search instead of the project root"))
          :function
          (my/gptel-tool-safely
           (lambda (pattern &optional path)
             (my/gptel-rg pattern (my/gptel-tool-path (or path "."))))))

         ;; search_project follows the current project, so from a code repo it
         ;; can't reach the notes; this one always searches `org-directory'.
         (gptel-make-tool
          :name "search_org"
          :category "local"
          :description (format "Search the user's org notes in %s for a regular
expression with ripgrep. Only .org and .org_archive files are searched, and the
match ignores case unless the pattern has a capital letter. Returns matching
lines as path:line:text with absolute paths, which read_file accepts as is."
                               (abbreviate-file-name
                                (expand-file-name org-directory)))
          :args '((:name "pattern" :type string
                   :description "Regular expression (ripgrep syntax)")
                  (:name "path" :type string :optional t
                   :description "Subdirectory or file of the notes to search instead of all of them, relative to the notes directory"))
          :function
          (my/gptel-tool-safely
           (lambda (pattern &optional path)
             ;; Notes are prose, so lowercase patterns should match any case;
             ;; the org type keeps attachments and exports out of the results.
             (my/gptel-rg pattern (my/gptel-tool-path (or path ".") org-directory)
                          "--smart-case" "--type=org"))))

         (gptel-make-tool
          :name "list_buffers"
          :category "local"
          :description "List the buffers open in Emacs, one per line, with the
file each one visits, if any."
          :args nil
          :function
          (my/gptel-tool-safely
           (lambda ()
             (mapconcat (lambda (b)
                          (if-let* ((file (buffer-file-name b)))
                              (format "%s\t%s" (buffer-name b) file)
                            (buffer-name b)))
                        ;; A leading space marks Emacs's internal buffers.
                        (seq-remove (lambda (b)
                                      (string-prefix-p " " (buffer-name b)))
                                    (buffer-list))
                        "\n"))))

         (gptel-make-tool
          :name "read_buffer"
          :category "local"
          :description "Return the current text of an Emacs buffer, including
unsaved changes. Use list_buffers to find buffer names."
          :args '((:name "name" :type string :description "Buffer name"))
          :function
          (my/gptel-tool-safely
           (lambda (name)
             (let ((buffer (or (get-buffer name)
                               (error "No buffer named %s" name))))
               ;; A buffer visiting a .gpg file holds its decrypted text.
               (when-let* ((file (buffer-file-name buffer))
                           ((not (file-remote-p file)))
                           ((my/gptel-tool-denied-p file)))
                 (error "Buffer %s visits %s, which is off limits" name file))
               (with-current-buffer buffer
                 (my/gptel-tool-cap
                  (buffer-substring-no-properties (point-min) (point-max))))))))

         (gptel-make-tool
          :name "write_file"
          :category "local"
          :confirm t
          :description "Create or overwrite a file with the given content,
creating parent directories as needed. Relative paths are resolved against the
project root. The user is asked to approve every call."
          :args '((:name "path" :type string :description "Path of the file to write")
                  (:name "content" :type string :description "Full new content of the file"))
          :function
          (my/gptel-tool-safely
           (lambda (path content)
             (let ((file (my/gptel-tool-path path)))
               (make-directory (file-name-directory file) t)
               (write-region content nil file nil 'silent)
               ;; Refresh an unmodified buffer visiting the file, so Emacs
               ;; doesn't keep showing the old text.
               (when-let* ((buffer (get-file-buffer file)))
                 (with-current-buffer buffer
                   (unless (buffer-modified-p)
                     (revert-buffer t t t))))
               (format "Wrote %d characters to %s" (length content) file))))))))
