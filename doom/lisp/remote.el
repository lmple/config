;;; $DOOMDIR/lisp/remote.el -*- lexical-binding: t; -*-
;;
;; Remote machines over TRAMP. `C-x d /ssh:' TAB already completes the hosts
;; of ~/.ssh/config, but the TAB is easy to miss and the path syntax has to
;; be remembered; `C-c o s' is one pick from a list, and gives the host a
;; workspace of its own: Dired there on the left, a shell logged in on the
;; right, as `C-c p p' does for a project.

(defun my/ssh-config-hosts (&optional file)
  "Return the host names on the Host lines of FILE, ~/.ssh/config by default.
A Host line may name several hosts.  Patterns (with *, ? or a leading !)
stand for many hosts or exclude one, so they are left out.  Files pulled
in with Include are not read.  Return nil when FILE can't be read."
  (let ((file (expand-file-name (or file "~/.ssh/config"))))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        ;; ssh's keywords are case-insensitive and may be followed by =;
        ;; the whitespace or = after Host keeps HostName from matching
        (let ((case-fold-search t)
              (names '()))
          (while (re-search-forward "^[ \t]*host[ \t=]+\\(.*\\)$" nil t)
            (setq names (append names (split-string (match-string-no-properties 1)))))
          (delete-dups
           (seq-remove (lambda (name) (string-match-p "[*?!]" name)) names)))))))

(defun my/ssh-terminal (host)
  "Switch to a local terminal logged in to HOST over ssh, creating it if needed.
The buffer is \"HOST :: ssh\", in zellij session emacs-ssh-<host>, which
outlives Emacs, so after a crash this reattaches to the same login.  The
session has no project hash, so `my/project-reattach-terminals' never
takes it.  Returns the buffer."
  ;; ssh is typed into the session's zsh rather than exec'd, so logging out
  ;; leaves a local shell in the pane instead of ending the session.
  (my/ghostel-session (expand-file-name "~/")
                      (format "%s :: ssh" host)
                      (my/zellij-safe-name
                       (concat "emacs-ssh-" (truncate-string-to-width host 32)))
                      (concat "ssh " (shell-quote-argument host))))

(defun my/ssh-workspace (host)
  "Open workspace HOST: Dired in HOST's home on the left, ssh on the right.
Dired goes over TRAMP's ssh method; the terminal is `my/ssh-terminal'.
When the workspace already exists, only switch to it, leaving its windows
as they are.  HOST is read with completion over `my/ssh-config-hosts';
another host, or user@host, can be typed as well."
  (interactive
   (list (completing-read "SSH host: " (my/ssh-config-hosts))))
  (when (string-empty-p host)
    (user-error "No host given"))
  (if (+workspace-exists-p host)
      (+workspace-switch host)
    (+workspace-switch host t)
    ;; A new workspace starts on the fallback buffer; make sure it is the only
    ;; window before splitting.
    (delete-other-windows)
    (dired (format "/ssh:%s:~/" host))
    (let ((dired-window (selected-window)))
      (select-window (split-window-right))
      (my/ssh-terminal host)
      (select-window dired-window))))

(map! :leader
      :desc "SSH host workspace" "o s" #'my/ssh-workspace)
