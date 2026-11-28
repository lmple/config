;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Catppuccin (catppuccin-theme in packages.el) in its Mocha flavour, which
;; must be set before Doom loads the theme. Ashen stays vendored in themes/,
;; so `M-x load-theme RET ashen' still compares the two.
(setq catppuccin-flavor 'mocha)
(setq doom-theme 'catppuccin)

;; Catppuccin sets term-color-* but not ansi-color-*, which ghostel's
;; ghostel-color-* faces inherit, so ghostel would fall back to Emacs's bright
;; defaults. These are alacritty/theme.toml's 16 colours, so a terminal looks
;; the same in Emacs and Alacritty. Bright is normal but for black and white.
(custom-theme-set-faces! 'catppuccin
  '(ansi-color-black          :foreground "#45475a" :background "#45475a")
  '(ansi-color-red            :foreground "#f38ba8" :background "#f38ba8")
  '(ansi-color-green          :foreground "#a6e3a1" :background "#a6e3a1")
  '(ansi-color-yellow         :foreground "#f9e2af" :background "#f9e2af")
  '(ansi-color-blue           :foreground "#89b4fa" :background "#89b4fa")
  '(ansi-color-magenta        :foreground "#f5c2e7" :background "#f5c2e7")
  '(ansi-color-cyan           :foreground "#94e2d5" :background "#94e2d5")
  '(ansi-color-white          :foreground "#bac2de" :background "#bac2de")
  '(ansi-color-bright-black   :foreground "#585b70" :background "#585b70")
  '(ansi-color-bright-red     :foreground "#f38ba8" :background "#f38ba8")
  '(ansi-color-bright-green   :foreground "#a6e3a1" :background "#a6e3a1")
  '(ansi-color-bright-yellow  :foreground "#f9e2af" :background "#f9e2af")
  '(ansi-color-bright-blue    :foreground "#89b4fa" :background "#89b4fa")
  '(ansi-color-bright-magenta :foreground "#f5c2e7" :background "#f5c2e7")
  '(ansi-color-bright-cyan    :foreground "#94e2d5" :background "#94e2d5")
  '(ansi-color-bright-white   :foreground "#a6adc8" :background "#a6adc8"))
(setq display-line-numbers-type t)
(setq font-lock-maximum-decoration t)
(setq org-directory "~/org/")

(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 13)
      doom-big-font (font-spec :family "FiraCode Nerd Font" :size 20))

;; Ctrl+click → go to definition
(global-set-key [C-down-mouse-1] #'ignore)
(global-set-key [C-mouse-1] (lambda (event)
                              (interactive "e")
                              (goto-char (posn-point (event-start event)))
                              (xref-find-definitions
                               (xref-backend-identifier-at-point
                                (xref-find-backend)))))

;; Disable vc for security reasons
;; provide the name of the branch without vc
(setq vc-handled-backends nil)
(defun my/git-branch ()
  (let ((head-file (locate-dominating-file default-directory ".git/HEAD")))
    (when head-file
      (with-temp-buffer
        (insert-file-contents (expand-file-name ".git/HEAD" head-file))
        (when (looking-at "ref: refs/heads/\\(.+\\)")
          (match-string 1))))))

(add-to-list 'global-mode-string
             '(:eval (when-let ((b (my/git-branch)))
                       (propertize (format "  %s" b) 'face 'success))))

;; Doom only reverts buffers on buffer/window/frame switch, so a file changed
;; by an external tool (Claude Code, git) stays stale while it is on screen.
;; File notifications (inotify) make the global mode cheap: no polling.
;; `after!' because Doom's own autorevert :config sets use-notify to nil when
;; the package loads, which would override a plain setq here.
(after! autorevert
  (setq auto-revert-use-notify t
        auto-revert-avoid-polling t))
(global-auto-revert-mode +1)

;; Treemacs moves to the file being edited. `after!' so this runs after Doom's
;; own treemacs setup.
(after! treemacs
  (treemacs-follow-mode +1))

(defun my/treemacs-focus-or-toggle ()
  "Go to treemacs if it is open, close it if already there, else open it.
Doom's `+treemacs/toggle' closes a visible treemacs even from a file,
so reaching an open one took a close and a reopen."
  (interactive)
  (require 'treemacs)
  (let ((window (treemacs-get-local-window)))
    (cond ((and window (eq window (selected-window)))
           (delete-window window))
          (window (select-window window))
          (t (+treemacs/toggle)))))

(map! :leader
      :desc "Project sidebar" "o p" #'my/treemacs-focus-or-toggle)

(load! "lisp/terminals")
(load! "lisp/agents")
(load! "lisp/remote")
(load! "lisp/documents")
(load! "lisp/lang-python")
(load! "lisp/lang-js")
(load! "lisp/llm")
(load! "lisp/llm-tools")
(load! "lisp/lang-lean")
(load! "lisp/lang-quint")

;;; Local extra config
(let ((extra (expand-file-name "extra_config.el" doom-user-dir)))
  (when (file-exists-p extra)
    (load! extra)))
