;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;; Python ────────────────────────────────────────────────────
(package! pyvenv-auto)
(package! flymake-ruff)
(package! flymake-collection)
(package! ghostel)

;; AI
(package! claude-code-ide
  :recipe (:host github :repo "manzaltu/claude-code-ide.el"))

;; Lean 4
(package! lean4-mode
  :recipe (:host github
           :repo "leanprover-community/lean4-mode"
           :files ("*.el" "data")))

;;; Local extra packages
(let ((extra (expand-file-name "extra_packages.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))
