;;; lisp/lang-python.el -*- lexical-binding: t; -*-

;;; Python ─────────────────────────────────────────────────────────────────────

;;; Trust ──────────────────────────────────────────────────────────────────────
;; Opening a .py file used to run the project's own code: pyvenv-auto activated
;; any .venv it found, so mypy came from .venv/bin, and mypy imports the plugins
;; the project's config names. Language servers run project code too, which is
;; why lsp-mode asks once per project. Reuse that answer for the venv and mypy:
;; one decision per project, kept in lsp-mode's session file. Ruff (pipx, no
;; plugins) runs either way.

(use-package! pyvenv-auto
  :commands pyvenv-auto-run)

(defun my/python-project-trusted-p (file)
  "Non-nil if FILE's project may run its venv, mypy and language server.
Projects lsp-mode already imported are trusted and blocklisted ones aren't;
for any other, ask once and record the answer the way lsp-mode's own prompt
does, so it doesn't ask again.  Quitting the question records nothing."
  (require 'lsp-mode)
  (let ((session (lsp-session)))
    (cond
     ((or (null file) (file-remote-p file) noninteractive) nil)
     ((lsp-find-session-folder session file) t)
     ((seq-some (lambda (dir) (lsp-f-ancestor-of? dir file))
                (lsp-session-folders-blocklist session))
      nil)
     (t
      ;; The root lsp-mode itself would suggest, so both agree on the project.
      (let ((root (lsp-f-canonical (lsp--suggest-project-root))))
        (condition-case nil
            (if (y-or-n-p
                 (format "Trust %s? It runs its venv, mypy and language server "
                         (abbreviate-file-name root)))
                (progn (lsp-workspace-folders-add root) t)
              ;; lsp--calculate-root skips blocklisted files, so Doom's lsp!
              ;; then starts nothing here either. The slot is set by offset,
              ;; found at run time: this file is macroexpanded and compiled
              ;; (doom doctor) before lsp-mode loads, so any `setf' on the
              ;; struct, its accessor's or `cl-struct-slot-value''s, fails then.
              (let ((slot (cl-struct-slot-offset 'lsp-session 'folders-blocklist)))
                (unless (member root (aref session slot))
                  (aset session slot (cons root (aref session slot)))))
              (lsp--persist-session session)
              nil)
          (quit nil)))))))

(defun my/python-trusted-tools-h ()
  "Activate the project's venv and enable mypy, if the project is trusted."
  (when (my/python-project-trusted-p buffer-file-name)
    (pyvenv-auto-run)
    (my/python-flymake-mypy-h)))

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
        '(ruff-isort ruff)))

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
;; Not hooked directly: `my/python-trusted-tools-h' runs it after the venv.
(add-hook! '(python-mode-hook python-ts-mode-hook) #'my/python-trusted-tools-h)
