;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;; Python ────────────────────────────────────────────────────
(package! pyenv-mode)
(package! pyvenv-auto)
(package! flymake-ruff)
(package! flymake-collection)

(package! ghostel)

(package! claude-code-ide
  :recipe (:host github :repo "manzaltu/claude-code-ide.el"))

;;; Local extra packages
(let ((extra (expand-file-name "extra_packages.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))
