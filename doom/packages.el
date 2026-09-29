;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;; Themes ────────────────────────────────────────────────────
(package! ashen-theme
  :recipe (:host codeberg :repo "ficd/ashen"
           :files ("emacs/ashen-theme.el")))

;;; Python ────────────────────────────────────────────────────
(package! pyenv-mode)
(package! pyvenv-auto)
(package! flymake-ruff)
(package! flymake-collection)
(package! ghostel)

;; AI
(package! claude-code-ide
  :recipe (:host github :repo "manzaltu/claude-code-ide.el"))

(package! shell-maker)
(package! acp)
(package! agent-shell)

;;; Local extra packages
(let ((extra (expand-file-name "extra_packages.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))
