;;; lisp/lang-python.el -*- lexical-binding: t; -*-

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
(add-hook! '(python-mode-hook python-ts-mode-hook) #'my/python-flymake-mypy-h)
