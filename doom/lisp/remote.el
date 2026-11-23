;;; $DOOMDIR/lisp/remote.el -*- lexical-binding: t; -*-
;;
;; Remote machines over TRAMP. `C-x d /ssh:' TAB already completes the hosts
;; of ~/.ssh/config, but the TAB is easy to miss and the path syntax has to
;; be remembered; `C-c o s' is the same as one pick from a list.

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

(defun my/ssh-dired (host)
  "Open Dired in HOST's home directory, over TRAMP's ssh method.
HOST is read with completion over `my/ssh-config-hosts'; another host,
or user@host, can be typed as well."
  (interactive
   (list (completing-read "SSH host: " (my/ssh-config-hosts))))
  (when (string-empty-p host)
    (user-error "No host given"))
  (dired (format "/ssh:%s:~/" host)))

(map! :leader
      :desc "Dired on an SSH host" "o s" #'my/ssh-dired)
