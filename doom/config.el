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

;; Load and configure tlc2langgraph
(use-package! tlc2langgraph
  :commands (tlc2langgraph-visualize
             tlc2langgraph-generate
             tlc2langgraph-refresh-diagram)
  :init
  ;; Optional: Set custom keybindings under a leader key
  (map! :leader
        (:prefix ("t" . "TLA+")
         :desc "Visualize TLA+ spec" "v" #'tlc2langgraph-visualize
         :desc "Generate Python code" "g" #'tlc2langgraph-generate
         :desc "Refresh diagram" "r" #'tlc2langgraph-refresh-diagram))

  :config
  ;; Configuration
  (setq tlc2langgraph-parser-backend 'apalache)
  (setq tlc2langgraph-layout-algorithm 'hierarchical)
  (setq tlc2langgraph-max-states-display 50)
  (setq tlc2langgraph-generate-invariant-checks t))

(use-package! minuet
  :config
  (setq minuet-provider 'openai-fim-compatible)
  (setq minuet-api-key "ollama")
  (setq minuet-openai-fim-compatible-options
        '(:end-point "http://localhost:11434/v1/completions"
          :model "qwen3.5:9b"
          :api-key "ollama")))
