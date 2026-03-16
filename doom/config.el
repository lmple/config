;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'mario-nes)
(setq display-line-numbers-type t)
(setq org-directory "~/org/")

(after! python
  ;; Use system Python by default
  (setq python-shell-interpreter "python3")

  ;; Automatically activate venv when found
  (setq pyvenv-mode-line-indicator '(pyvenv-virtual-env-name ("[venv:" pyvenv-virtual-env-name "] ")))

  ;; Auto-activate .venv if it exists
  (add-hook 'python-mode-hook
            (lambda ()
              (let ((venv-path (locate-dominating-file default-directory ".venv")))
                (when venv-path
                  (pyvenv-activate (expand-file-name ".venv" venv-path)))))))

(require 'acp)
(require 'agent-shell)
(setq agent-shell-anthropic-authentication
      (agent-shell-anthropic-make-authentication :login t))
