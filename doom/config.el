;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; ashen is vendored in themes/, which Doom puts on custom-theme-load-path.
(setq doom-theme 'ashen)

;; The Ashen theme sets no terminal colours, so ghostel (its ghostel-color-*
;; faces inherit ansi-color-*) fell back to Emacs's bright defaults, and `ls'
;; drew directories in a vivid blue. These are kitty/theme.conf's 16 colours,
;; so a terminal looks the same in Emacs and kitty. Set here, not in the
;; vendored theme, which an update overwrites. Bright is normal but for black.
(custom-theme-set-faces! 'ashen
  '(ansi-color-black          :foreground "#121212" :background "#121212")
  '(ansi-color-red            :foreground "#b14242" :background "#b14242")
  '(ansi-color-green          :foreground "#d87c4a" :background "#d87c4a")
  '(ansi-color-yellow         :foreground "#e49a44" :background "#e49a44")
  '(ansi-color-blue           :foreground "#4a8b8b" :background "#4a8b8b")
  '(ansi-color-magenta        :foreground "#a7a7a7" :background "#a7a7a7")
  '(ansi-color-cyan           :foreground "#b4b4b4" :background "#b4b4b4")
  '(ansi-color-white          :foreground "#d5d5d5" :background "#d5d5d5")
  '(ansi-color-bright-black   :foreground "#949494" :background "#949494")
  '(ansi-color-bright-red     :foreground "#b14242" :background "#b14242")
  '(ansi-color-bright-green   :foreground "#d87c4a" :background "#d87c4a")
  '(ansi-color-bright-yellow  :foreground "#e49a44" :background "#e49a44")
  '(ansi-color-bright-blue    :foreground "#4a8b8b" :background "#4a8b8b")
  '(ansi-color-bright-magenta :foreground "#a7a7a7" :background "#a7a7a7")
  '(ansi-color-bright-cyan    :foreground "#b4b4b4" :background "#b4b4b4")
  '(ansi-color-bright-white   :foreground "#d5d5d5" :background "#d5d5d5"))
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

(load! "lisp/terminals")
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
