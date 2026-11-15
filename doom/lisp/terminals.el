;;; lisp/terminals.el -*- lexical-binding: t; -*-

;; Emacs inherits the environment of whatever shell started it (the `emacs'
;; alias starts the daemon there), and passes it on to every terminal.
;; - From a zellij pane: zshrc took every ghostel shell for one already in
;;   zellij, and `zellij action' targeted a stale session.
;; - From inside Claude Code (e.g. `! emacs'): every agent in a terminal took
;;   itself for that session's child and turned transcript saving off, and the
;;   session's messaging token reached every subprocess.
;; Settings like CLAUDE_CODE_DISABLE_* are not markers and stay.
(dolist (var '("ZELLIJ" "ZELLIJ_SESSION_NAME" "ZELLIJ_PANE_ID"
               "CLAUDECODE" "CLAUDE_PID" "CLAUDE_EFFORT"
               "CLAUDE_CODE_CHILD_SESSION" "CLAUDE_CODE_SESSION_ID"
               "CLAUDE_CODE_SESSION_ATTENDED" "CLAUDE_CODE_ENTRYPOINT"
               "CLAUDE_CODE_EXECPATH" "CLAUDE_CODE_MESSAGING_SOCKET"
               "CLAUDE_CODE_MESSAGING_TOKEN"))
  (setenv var nil))

;; Always a fresh terminal at the project root, never a switch to an open one:
;; the workspace's agent and shell already cover the reusable terminals.
;; Defined below, with the other terminals backed by zellij sessions.
(map! :leader
      :desc "New project terminal" "o T" #'my/project-ghostel-new)

;; ghostel's own URL detection stops at newlines, including the ones it inserts
;; for soft wraps (marked `ghostel-wrap'), so a long URL opens truncated.
;; Dropping those newlines first rejoins it. Inside zellij, where project
;; terminals run, this can't help: zellij draws finished rows
;; (zellij-org/zellij#3436), use its Alt u picker. It still works in plain
;; ghostel terminals (M-x ghostel), which skip zellij.
(defun my/buffer-urls ()
  "Return the URLs in the current buffer, newest first, soft wraps undone."
  (let ((text (buffer-string))
        (urls '()))
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (search-forward "\n" nil t)
        (when (get-text-property (match-beginning 0) 'ghostel-wrap)
          (replace-match "")))
      (goto-char (point-min))
      (while (re-search-forward
              "https?://[^ \t\n\r\"'<>`]*[^ \t\n\r\"'<>`.,;:!?)]" nil t)
        (push (match-string-no-properties 0) urls)))
    (delete-dups urls)))

(defun my/browse-url-in-buffer ()
  "Pick a URL from the current buffer, newest first, and open it."
  (interactive)
  (let ((urls (or (my/buffer-urls) (user-error "No URLs in this buffer"))))
    (browse-url
     (completing-read
      "Open URL: "
      ;; Keep newest-first: completion UIs re-sort plain lists by default
      (lambda (string pred action)
        (if (eq action 'metadata)
            '(metadata (display-sort-function . identity))
          (complete-with-action action urls string pred)))
      nil t))))

(map! :leader
      :desc "URL in buffer" "o u" #'my/browse-url-in-buffer)

;; ghostel isn't loaded yet, so without these the `let's below would bind
;; them lexically: ghostel would never see them, and its defcustoms error
;; when autoloaded inside such a binding.
(defvar ghostel-buffer-name)
(defvar ghostel-environment)

(defun my/zellij-safe-name (string)
  "Return STRING with what zellij session names can't hold replaced by -."
  (replace-regexp-in-string "[^A-Za-z0-9_-]" "-" string))

(defun my/project-zellij-affixes ()
  "Return (PREFIX . SUFFIX) around NAME in the project's zellij sessions.
Sessions are emacs-<project>-NAME-<hash>, for the project at
`default-directory'."
  (let ((project (project-current t)))
    ;; The hash keeps projects with the same directory name apart, the emacs-
    ;; prefix keeps zshrc's reattach of crashed terminals off them, and the
    ;; truncation keeps zellij's socket path under its limit.
    (cons (my/zellij-safe-name
           (format "emacs-%s-" (truncate-string-to-width
                                (project-name project) 32)))
          (concat "-" (substring (md5 (expand-file-name
                                       (project-root project)))
                                 0 6)))))

(defun my/project-terminal-names (name)
  "Return (BUFFER . SESSION) for project terminal NAME at `default-directory'.
BUFFER is \"<project> :: NAME\" and SESSION names its zellij session."
  (pcase-let ((`(,prefix . ,suffix) (my/project-zellij-affixes)))
    (cons (format "%s :: %s" (project-name (project-current t)) name)
          (concat prefix
                  (my/zellij-safe-name (truncate-string-to-width name 16))
                  suffix))))

(defun my/zellij-live-sessions ()
  "Return the names of the zellij sessions that are running, not exited."
  (delq nil
        (mapcar (lambda (line)
                  (and (not (string-search "EXITED" line))
                       (car (split-string line))))
                ;; zellij exits non-zero when there is no session at all
                (ignore-errors
                  (process-lines "zellij" "list-sessions" "--no-formatting")))))

(defun my/ghostel-session (dir buffer session &optional command)
  "Switch to ghostel terminal BUFFER, creating it in DIR if needed.
The terminal runs in zellij session SESSION, which outlives Emacs, so after
a crash this reattaches to it.  COMMAND, if non-nil, runs in the session
when it is created, not on a reattach.  Returns the buffer."
  ;; Not `ghostel-project': it keys a terminal by project root alone, so a
  ;; second call returns the first terminal whatever `ghostel-buffer-name'
  ;; says.  Plain `ghostel' keys it by buffer name, one slot per BUFFER.
  (let* ((default-directory dir)
         (ghostel-buffer-name buffer)
         ;; Read by zshrc's zellij auto-start
         (ghostel-environment
          (append (list (concat "MY_ZELLIJ_SESSION=" session))
                  (and command (list (concat "MY_ZELLIJ_RUN=" command)))
                  (bound-and-true-p ghostel-environment))))
    (ghostel)))

(defun my/project-ghostel (name &optional command)
  "Switch to the project's ghostel terminal NAME, creating it if needed.
The terminal starts in the root of the project at `default-directory', in
buffer \"<project> :: NAME\", with its own zellij session and COMMAND as
in `my/ghostel-session'.  Returns the buffer."
  (let ((default-directory (project-root (project-current t))))
    (pcase-let ((`(,buffer . ,session) (my/project-terminal-names name)))
      (my/ghostel-session default-directory buffer session command))))

(defun my/project-ghostel-new ()
  "Open a new project terminal, \"<project> :: term-N\", in its own session.
N is the lowest number taken by neither a buffer nor a live session, so a
session that survived a crash is left for \\[my/project-reattach-terminals]."
  (interactive)
  (let ((live (my/zellij-live-sessions)))
    (named-let next ((n 1))
      (let* ((name (format "term-%d" n))
             (names (my/project-terminal-names name)))
        (if (or (get-buffer (car names)) (member (cdr names) live))
            (next (1+ n))
          (my/project-ghostel name))))))

(defun my/project-reattach-terminals ()
  "Reattach the project's live zellij sessions that have no buffer.
After an Emacs crash, this brings back every project terminal that is
still running, each in its \"<project> :: NAME\" buffer, without
changing the windows.  Agents are not started again: they are still
running in their sessions."
  (interactive)
  (pcase-let* ((`(,prefix . ,suffix) (my/project-zellij-affixes))
               (names (delq nil
                            (mapcar (lambda (session)
                                      (and (string-prefix-p prefix session)
                                           (string-suffix-p suffix session)
                                           (> (length session)
                                              (+ (length prefix) (length suffix)))
                                           (substring session (length prefix)
                                                      (- (length suffix)))))
                                    (my/zellij-live-sessions))))
               (detached (seq-remove
                          (lambda (name)
                            (get-buffer (car (my/project-terminal-names name))))
                          names)))
    (save-window-excursion (mapc #'my/project-ghostel detached))
    (message (if detached
                 (format "Reattached %s" (string-join detached ", "))
               "No detached terminals in this project"))))

(map! :leader
      :desc "Reattach project terminals" "o z" #'my/project-reattach-terminals)

(defvar my/project-agent "claude"
  "Command of the coding agent `my/project-terminals' starts, e.g. \"pi\".
It also names the agent's buffer, \"<project> :: <command>\", and its zellij
session, so neither is reused for another agent.  Set it per machine in
extra_config.el.")

(defvar my/project-agent-share 0.65
  "Fraction of the agent/shell split that the agent's window gets.
The shell keeps the rest, which is still enough for a few commands.")

(defun my/project-terminals (&optional dir)
  "Pick a file in the project at DIR, then open the agent and a shell beside it.
DIR defaults to `default-directory'.  The file goes on the left, the agent
\(`my/project-agent') top-right and the shell bottom-right.  Cancelling the
picker with \\[keyboard-quit] skips the file and puts the agent and the
shell side by side.  Either way the agent gets `my/project-agent-share' of
the space it shares with the shell.
The agent and the shell run in zellij sessions that outlive Emacs: switching
back to a project, even after an Emacs crash, reattaches them, and the agent
is only started when its session is created."
  (interactive)
  (let* ((default-directory (or dir default-directory))
         (file-window (progn
                        (delete-other-windows)
                        ;; Catch C-g here so cancelling only skips the file
                        ;; instead of aborting the terminals as well.
                        (condition-case nil
                            (progn (doom-project-find-file default-directory)
                                   (selected-window))
                          (quit nil)))))
    (when file-window
      (select-window (split-window-right)))
    ;; Run by the session's shell rather than exec'd, so quitting the agent
    ;; leaves a usable shell instead of ending the session.
    (my/project-ghostel my/project-agent my/project-agent)
    ;; The agent's window is still selected, and a positive SIZE goes to the
    ;; selected (top or left) window, so this sizes the agent, not the shell.
    (select-window
     (if file-window
         (split-window-below
          (round (* my/project-agent-share (window-total-height))))
       (split-window-right
        (round (* my/project-agent-share (window-total-width))))))
    (my/project-ghostel "shell")
    (when file-window
      (select-window file-window))))

;; Runs after `C-c p p' instead of Doom's default, `doom-project-find-file',
;; which `my/project-terminals' still calls first.
(setq +workspaces-switch-project-function #'my/project-terminals)

;; Doom reuses and renames the current workspace on project switch when it
;; holds no file buffers, which is always true of a fresh `main' because
;; *scratch* never counts. Always open a new workspace so `main' and its
;; *scratch* stay put.
(setq +workspaces-on-switch-project-behavior t)
