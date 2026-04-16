;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;; TLA+ specification language ───────────────────────────────
(package! tla-mode)

;;; Python ────────────────────────────────────────────────────
(package! pyenv-mode)
(package! pyvenv-auto)
(package! flymake-ruff)
(package! flymake-collection)

;;; Gen AI ────────────────────────────────────────────────────
(package! shell-maker)
(package! acp)
(package! agent-shell)

(package! claude-code-ide
  :recipe (:host github :repo "manzaltu/claude-code-ide.el"))

;;; TLA
(package! tla-ts-mode
  :recipe (:host github :repo "Davidbrcz/tla-ts-mode"))

(package! tla-tools
  :recipe (:host github
           :repo "mrc/tla-tools"
           :files ("tla-tools.el")))  ; exclude tla-pcal-mode.el

(package! polymode)

;;; Local extra packages
(let ((extra (expand-file-name "extra_packages.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))
