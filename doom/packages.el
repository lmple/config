;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;; Theme
;; Catppuccin; config.el picks the Mocha flavour. Pinned so an upstream
;; change can't restyle Emacs on the next doom sync.
(package! catppuccin-theme :pin "56c3cbe1fee8b04dd7331738df1a0b9bdc6f71bd")

;;; Terminal
(package! ghostel)
;; Runs the project agent (lisp/terminals.el): Claude Code in a ghostel buffer,
;; wired to Emacs over MCP for diffs, selection and diagnostics
(package! claude-code-ide
  :recipe (:host github :repo "manzaltu/claude-code-ide.el"))

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
