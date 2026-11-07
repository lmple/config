;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-dracula)
(setq display-line-numbers-type t)
(setq font-lock-maximum-decoration t)
(setq org-directory "~/org/")

(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 13)
      doom-big-font (font-spec :family "FiraCode Nerd Font" :size 20))

;; Ctrl+click → go to definition
(global-set-key [C-down-mouse-1] #'ignore)
(global-set-key [C-mouse-1] (lambda (event)
                              (interactive "e")
                              (goto-char (posn-point (event-start event)))
                              (xref-find-definitions
                               (xref-backend-identifier-at-point
                                (xref-find-backend)))))

;; Disable vc for security reasons
;; provide the name of the branch without vc
(setq vc-handled-backends nil)
(defun my/git-branch ()
  (let ((head-file (locate-dominating-file default-directory ".git/HEAD")))
    (when head-file
      (with-temp-buffer
        (insert-file-contents (expand-file-name ".git/HEAD" head-file))
        (when (looking-at "ref: refs/heads/\\(.+\\)")
          (match-string 1))))))

(add-to-list 'global-mode-string
             '(:eval (when-let ((b (my/git-branch)))
                       (propertize (format "  %s" b) 'face 'success))))

(load! "lisp/terminals")
(load! "lisp/documents")
(load! "lisp/lang-python")
(load! "lisp/lang-js")

;;; Local extra config
(let ((extra (expand-file-name "extra_config.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))

(load! "lisp/llm")

;; Tools let the local model look around on its own. Reading never asks;
;; writing asks before every call (gptel's `:confirm').
(defconst my/gptel-tool-max-chars 32000
  "Cap on text a tool returns, ~8k tokens: half the 16k context window.")

(defun my/gptel-tool-path (path)
  "Expand PATH against the current project root, or `default-directory'."
  (expand-file-name path (or (doom-project-root) default-directory)))

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
             (with-temp-buffer
               (insert-file-contents (my/gptel-tool-path path))
               (my/gptel-tool-cap (buffer-string))))))

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
             (my/gptel-rg pattern (expand-file-name (or path ".") org-directory)
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

;;; Lean 4
;; The Lean server sends workspace/inlayHint/refresh, which lsp-mode's request
;; dispatcher doesn't know and warns about on every re-elaboration. It still
;; replies nil (the correct response), so only the warning needs to go.
(after! lsp-mode
  (defadvice! my/lsp-ignore-inlay-hint-refresh-a (message &rest args)
    :before-until #'lsp-warn
    (and (equal message "Unknown request method: %s")
         (equal (car args) "workspace/inlayHint/refresh"))))

;;; Quint
;; The plugins come from a local quint checkout that isn't present on every
;; machine, so skip them instead of aborting startup when it's missing.
(let* ((quint-dir (expand-file-name "~/sources/quint/editor-plugins/emacs/"))
       (quint-mode-file (expand-file-name "quint-mode.el" quint-dir))
       (lsp-quint-file (expand-file-name "lsp-quint.el" quint-dir)))
  (when (file-exists-p quint-mode-file)
    (load quint-mode-file nil t)
    (add-to-list 'auto-mode-alist '("\\.qnt\\'" . quint-mode))
    ;; lsp-quint.el requires lsp-mode at load time, so defer it until lsp-mode
    ;; is loaded anyway instead of pulling it into startup.
    (after! lsp-mode
      (load lsp-quint-file nil t))
    ;; The server declares "." as a trigger character but answers only
    ;; requests marked as invoked, so lsp-mode's "."-triggered requests always
    ;; come back empty. Report them as invoked in Quint buffers.
    (defadvice! my/quint-lsp-completion-invoked-a (fn &rest args)
      :around #'lsp-completion--get-context
      (if (eq major-mode 'quint-mode)
          (let ((non-essential nil)) (apply fn args))
        (apply fn args)))
    ;; The server never completes plain names, so fall back to Quint's
    ;; keywords (reusing quint-mode.el's lists) and words from Quint buffers.
    (after! cape-keyword
      (add-to-list 'cape-keyword-list
                   (cons 'quint-mode (append quint-declarations quint-keywords
                                             quint-types quint-constants))))
    (add-hook! 'quint-mode-hook
      (defun my/quint-add-names-capf-h ()
        (add-hook 'completion-at-point-functions
                  (cape-capf-super #'cape-keyword #'cape-dabbrev) 20 t)))
    (add-hook 'quint-mode-local-vars-hook #'lsp! 'append)))
