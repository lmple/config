;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;;; TLA+ specification language ───────────────────────────────
(package! tla-mode)

;;;; Python ────────────────────────────────────────────────────
(package! pyenv-mode)
(package! pyvenv-auto)
(package! flymake-ruff)
(package! flymake-collection)

;;;; Gen AI ────────────────────────────────────────────────────
(package! shell-maker)
(package! acp)
(package! agent-shell)

(package! claude-code-ide
  :recipe (:host github :repo "manzaltu/claude-code-ide.el"))
