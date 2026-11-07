;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-dracula)
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
