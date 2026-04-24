;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-tomorrow-night)
(setq display-line-numbers-type t)
(setq font-lock-maximum-decoration t)
(setq org-directory "~/org/")

(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 13)
      doom-big-font (font-spec :family "FiraCode Nerd Font" :size 20)
      doom-variable-pitch-font (font-spec :family "Noto Sans" :size 13))

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

(after! eglot
  ;; Pyright's semantic tokens override tree-sitter highlights and leave
  ;; large swaths uncolored when theme faces are missing — disable them.
  (add-to-list 'eglot-ignored-server-capabilities :semanticTokensProvider)
  (setq-default eglot-workspace-configuration
                '(:python (:analysis
                           (:autoImportCompletions t
                            :useLibraryCodeForTypes t
                            :typeCheckingMode "basic")))))

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
  ;; Disable flycheck so flymake (eglot + ruff + mypy) is the sole checker
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

;;; TLA+ ───────────────────────────────────────────────────────────────────────

(use-package! tla-mode
  :mode ("\\.tla\\'" . tla-mode)
  :config
  ;; Point to the TLA+ tools jar if installed (adjust path as needed)
  (when-let ((tla-jar (or (getenv "TLA_JAR")
                          (cl-find-if #'file-exists-p
                                      '("/usr/local/lib/tla2tools.jar"
                                        "/opt/tla+/tla2tools.jar"
                                        "~/bin/tla2tools.jar")))))
    (setq tla-java-path (or (executable-find "java") "java")
          tla-tlatools-path tla-jar)))

;;; Claude code ───────────────────────────────────────────────────────────────
(require 'acp)
(require 'agent-shell)
(setq agent-shell-show-usage-at-turn-end t)
(setq agent-shell-show-context-usage-indicator t)

(use-package agent-shell
  :bind ("C-c C-$" . agent-shell))


(use-package! claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu) ; Set your favorite keybinding
  :config
  (claude-code-ide-emacs-tools-setup)) ; Optionally enable Emacs MCP tools

;;; TLA
(use-package! polymode)

(use-package tla-ts-mode
  :mode "\\.tla\\'"
  :ensure t
  :config
                                        ; The grammar is called tlaplus, but the mode is called tla
  (setq treesit-load-name-override-list '((tla "libtree-sitter-tlaplus" "tree_sitter_tlaplus")))
  )

;; Load only tla-tools.el, skip tla-pcal-mode.el
(with-eval-after-load 'polymode
  (require 'tla-tools))

(add-hook 'tla-ts-mode-hook #'tla-tools-error-regexp-add)

;;; Local extra config
(let ((extra (expand-file-name "extra_config.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))
