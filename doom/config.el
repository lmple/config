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

;;; Org ────────────────────────────────────────────────────────────────────────
;; Doom turns these prompts off, which lets an untrusted .org file run code via
;; an elisp: link, C-c C-c, or export. Re-enable them; this runs after Doom's
;; org-load-hook setup, so it wins.
(after! org
  (setq org-confirm-babel-evaluate t
        org-link-elisp-confirm-function #'yes-or-no-p))

;; Doom picks maim/scrot/gnome-screenshot, which are X11 tools and capture
;; nothing useful on KDE Wayland. Spectacle's background region mode blocks
;; until a region is selected, so org-download-screenshot waits for the file.
;; scrot is still installed only to quiet doom doctor, which checks for it.
(after! org-download
  (when (executable-find "spectacle")
    (setq org-download-screenshot-method "spectacle --background --nonotify --region --output %s")))

;;; LaTeX ──────────────────────────────────────────────────────────────────────
;; Doom picks the first installed viewer from this list and evince comes before
;; pdf-tools by default; keep compiled PDFs (with SyncTeX) inside Emacs.
(setq +latex-viewers '(pdf-tools))

;; Org's default sends .pdf to the system app, bypassing pdf-tools.
(after! org
  (setf (alist-get "\\.pdf\\'" org-file-apps nil nil #'equal) 'emacs))

;;; Python ─────────────────────────────────────────────────────────────────────

(use-package! pyvenv-auto
  :hook (python-mode . pyvenv-auto-run))

(use-package! pyenv-mode
  :hook (python-mode . pyenv-mode)
  :config
  (defun my/pyenv-switch ()
    "Pick a pyenv version with Vertico completion."
    (interactive)
    (let ((version (completing-read
                    "Switch pyenv: "
                    (pyenv-mode-versions)
                    nil t)))
      (pyenv-mode-set version)
      (message "Switched to %s" version)))

  (map! :mode python-mode
        "C-c v" #'my/pyenv-switch
        "C-c V" #'pyenv-mode-unset))

;; Pyright's semantic tokens would override tree-sitter highlights, but
;; lsp-mode leaves `lsp-semantic-tokens-enable' off by default (lean4-mode
;; turns it on locally), so nothing needs disabling here.
(after! lsp-pyright
  (setq lsp-pyright-type-checking-mode "basic"
        lsp-pyright-auto-import-completions t)
  ;; lsp-pyright has no defcustom for this one, so register it directly.
  (lsp-register-custom-settings
   '(("python.analysis.useLibraryCodeForTypes" t t))))

(after! apheleia
  ;; Python — ruff
  (setf (alist-get 'ruff-isort apheleia-formatters)
        '("ruff" "check" "--fix" "--select" "I" "--stdin-filename" filepath "-"))
  (setf (alist-get 'ruff apheleia-formatters)
        '("ruff" "format" "--stdin-filename" filepath "-"))
  (setf (alist-get 'python-mode apheleia-mode-alist)
        '(ruff-isort ruff))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist)
        '(ruff-isort ruff))
  ;; JS/TS — prettier
  (when (executable-find "prettier")
    (dolist (mode '(js-mode js-ts-mode typescript-mode typescript-ts-mode
                    tsx-ts-mode web-mode))
      (setf (alist-get mode apheleia-mode-alist) 'prettier))))

(use-package! flymake-ruff
  :defer t)

(defun my/python-flymake-ruff-h ()
  ;; Disable flycheck so flymake (pyright + ruff + mypy) is the sole checker.
  ;; lsp-mode defaults to flycheck, so point it at flymake for this buffer;
  ;; Doom starts lsp from the local-vars hook, after this has run.
  (setq-local lsp-diagnostics-provider :flymake)
  ;; eglot used to drop the built-in pyflakes backend; ruff already covers
  ;; those rules, so drop it here too to avoid duplicate diagnostics.
  (remove-hook 'flymake-diagnostic-functions #'python-flymake t)
  (flycheck-mode -1)
  (flymake-ruff-load))
(add-hook! '(python-mode-hook python-ts-mode-hook) #'my/python-flymake-ruff-h)

(use-package! flymake-collection
  :defer t)

(defun my/python-flymake-mypy-h ()
  ;; Prefer the venv's mypy (pyvenv-auto has already updated exec-path by now);
  ;; fall back to the global pipx install so checks still run outside a venv.
  (setq-local flymake-collection-mypy-executable
              (or (executable-find "mypy")
                  (expand-file-name "~/.local/bin/mypy")))
  (add-hook 'flymake-diagnostic-functions
            #'flymake-collection-mypy nil t))
(add-hook! '(python-mode-hook python-ts-mode-hook) #'my/python-flymake-mypy-h)

;;; JavaScript / TypeScript ────────────────────────────────────────────────────

(after! js2-mode
  (setq js2-basic-offset 2
        js-indent-level 2))

(after! typescript-mode
  (setq typescript-indent-level 2))

;;; Local extra config
(let ((extra (expand-file-name "extra_config.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))

;;; LLM ────────────────────────────────────────────────────────────────────────
;; gptel talks to a local llama-server, run in router mode by the
;; llama-server@home or llama-server@work user service (systemd/, see README)
;; with that machine's presets (llama/home.ini or llama/work.ini), through
;; the OpenAI-compatible API it exposes. The model list comes from the server,
;; so the presets file is the only list to edit.
(defconst my/gptel-llama-host "localhost:8080"
  "Where llama-server listens, as set in systemd/llama-server@.service.")

(defun my/gptel-llama-backend (models)
  "Register the llama-cpp gptel backend offering MODELS, a list of symbols.
Registering under the same name replaces the previous backend."
  (gptel-make-openai "llama-cpp"
    :stream t
    :protocol "http"
    :host my/gptel-llama-host
    :models (mapcar (lambda (name) (list name :capabilities '(tool-use)))
                    models)))

(defun my/gptel-llama-server-models ()
  "Return llama-server's models as a list of (NAME . LOADED-P), or nil.
Nil means the server couldn't be reached within a second."
  (when-let* ((buffer (ignore-errors
                        (url-retrieve-synchronously
                         (format "http://%s/v1/models" my/gptel-llama-host)
                         t t 1))))
    (unwind-protect
        (with-current-buffer buffer
          (goto-char (point-min))
          (when (and (looking-at "HTTP/[0-9.]+ 200")
                     (re-search-forward "\r?\n\r?\n" nil t))
            (seq-keep
             (lambda (model)
               ;; The router also lists every GGUF in the Hugging Face cache
               ;; ("cache"), but only presets get the flags from llama/*.ini.
               ;; A server started on a single model has no "source" at all.
               (when (equal (gethash "source" model "preset") "preset")
                 (cons (intern (gethash "id" model))
                       (when-let* ((status (gethash "status" model)))
                         (equal (gethash "value" status) "loaded")))))
             (gethash "data" (json-parse-buffer)))))
      (kill-buffer buffer))))

(defun my/gptel-llama-sync-models (&rest _)
  "Offer in gptel the models the running llama-server has presets for.
If the current model isn't one of them (say, the other machine's), switch to
the loaded model, or else the first one. Runs before `gptel-menu', so the menu
always shows what the server offers; does nothing if the server is down."
  (interactive)
  (if-let* ((models (my/gptel-llama-server-models)))
      (let ((backend (my/gptel-llama-backend (mapcar #'car models))))
        ;; Leave a different backend picked in the menu alone.
        (when (equal (gptel-backend-name gptel-backend) "llama-cpp")
          (setq gptel-backend backend)
          (unless (assq gptel-model models)
            (setq gptel-model (car (or (rassq t models) (car models))))))
        (when (called-interactively-p 'interactive)
          (message "llama-server offers: %s"
                   (mapconcat (lambda (m) (symbol-name (car m))) models ", "))))
    (when (called-interactively-p 'interactive)
      (message "llama-server isn't reachable at %s" my/gptel-llama-host))))

(after! gptel
  ;; Until the server answers, assume the home preset, so gptel still loads.
  (setq gptel-backend (my/gptel-llama-backend '(gemma-4-12b))
        gptel-model 'gemma-4-12b)
  (my/gptel-llama-sync-models)
  (advice-add 'gptel-menu :before #'my/gptel-llama-sync-models))

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
