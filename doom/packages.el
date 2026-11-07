;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;; Terminal
(package! ghostel)

;;; Python
(package! pyvenv-auto)
(package! flymake-ruff)
(package! flymake-collection)
;; Doom enables nose-mode in every test_*.py file, and its local-leader keys
;; (t a, t r) shadow python-pytest's. nose is dead on modern Python and tests
;; run with pytest. doom doctor still warns about nosetests: its check is
;; unconditional.
(package! nose :disable t)

;;; Lean 4
(package! lean4-mode
  :recipe (:host github
           :repo "leanprover-community/lean4-mode"
           :files ("*.el" "data")))

;;; Local extra packages
(let ((extra (expand-file-name "extra_packages.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))
