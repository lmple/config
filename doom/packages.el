;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;; Python ────────────────────────────────────────────────────
(package! pyenv-mode)
(package! pyvenv-auto)
(package! flymake-ruff)
(package! flymake-collection)
(package! ghostel)

;;; Local extra packages
(let ((extra (expand-file-name "extra_packages.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))
