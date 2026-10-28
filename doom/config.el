;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; ashen is vendored in themes/, which Doom puts on custom-theme-load-path.
(setq doom-theme 'ashen)
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

(map! :leader
      "o T" #'ghostel-project) ;; replace with your actual ghostty function

;;; Org ────────────────────────────────────────────────────────────────────────
;; Doom turns these prompts off, which lets an untrusted .org file run code via
;; an elisp: link, C-c C-c, or export. Re-enable them; this runs after Doom's
;; org-load-hook setup, so it wins.
(after! org
  (setq org-confirm-babel-evaluate t
        org-link-elisp-confirm-function #'yes-or-no-p))

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

;; Claude code
(use-package! claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu) ; Set your favorite keybinding
  :config
  (claude-code-ide-emacs-tools-setup)) ; Optionally enable Emacs MCP tools

(setq claude-code-ide-terminal-backend 'ghostel)

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
(let ((quint-mode-file (expand-file-name "~/sources/quint/editor-plugins/emacs/quint-mode.el")))
  (when (file-exists-p quint-mode-file)
    (load quint-mode-file nil t)
    (add-to-list 'auto-mode-alist '("\\.qnt\\'" . quint-mode))
    ;; init.el uses (lsp +eglot) and lsp-quint.el only targets lsp-mode, which
    ;; Doom never loads here, so register the server with eglot directly.
    (set-eglot-client! 'quint-mode '("quint-language-server" "--stdio"))
    (add-hook 'quint-mode-local-vars-hook #'lsp! 'append)))
