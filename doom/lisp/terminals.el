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

(defun my/terminal-role (buffer-name)
  "Return NAME from a \"<project> :: NAME\" BUFFER-NAME, or nil."
  ;; Greedy .* so a project name holding \" :: \" still yields the last part
  (and (string-match ".* :: \\(.+\\)\\'" buffer-name)
       (match-string 1 buffer-name)))

(defun my/terminal-task (title)
  "Return the task part of terminal TITLE, or nil.
Terminals run in zellij, which titles them \"<session> | <pane title>\";
the pane title is what the program set, e.g. a Claude Code session's name.
A shell sets none, which leaves just \"<session>\"."
  (and title
       (string-match " | \\(.+\\)\\'" title)
       (match-string 1 title)))

(defun my/ibuffer-format-with-term (format)
  "Return ibuffer FORMAT with term and title columns after its name column.
FORMAT is returned as is when it already has a term column, so reloading
this file doesn't add a second."
  (if (seq-some (lambda (item) (eq (car-safe item) 'term)) format)
      format
    (seq-mapcat (lambda (item)
                  (if (eq (car-safe item) 'name)
                      (list item
                            " " '(term 16 16 :left :elide)
                            " " '(title 30 30 :left :elide))
                    (list item)))
                format)))

;; Doom caps ibuffer's name column at 18 columns, so a long project name hides
;; whether a terminal is the agent, the shell or a term-N, and the mode column
;; says ghostel for all of them. The project is already shown by ibuffer's
;; per-project groups, so the role gets a column of its own. Several agents in
;; one project are all "claude" or "term-N" there, so a title column tells
;; them apart by the session's name, which follows /rename (refresh with g).
;; This runs after Doom's own `after! ibuffer', which sets the formats edited
;; here.
(after! ibuffer
  (define-ibuffer-column term (:name "Term")
    (or (and (derived-mode-p 'ghostel-mode)
             (my/terminal-role (buffer-name)))
        ""))
  (define-ibuffer-column title (:name "Title")
    (or (and (derived-mode-p 'ghostel-mode)
             (my/terminal-task (bound-and-true-p ghostel-title)))
        ""))
  (setq ibuffer-formats
        (mapcar #'my/ibuffer-format-with-term ibuffer-formats)))

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
\"claude\" runs as a claude-code-ide session (`my/project-claude-ide').
Any other agent runs in a zellij terminal, and the command also names its
buffer, \"<project> :: <command>\", and its zellij session, so neither is
reused for another agent.  Set it per machine in extra_config.el.")

(defun my/claude-ide-buffer-name (directory &optional instance)
  "Return \"<project> :: claude-ide\" for DIRECTORY, \":INSTANCE\" appended.
A `claude-code-ide-buffer-name-function', in the same \"<project> :: NAME\"
form as the other project terminals, so the ibuffer Term column shows it."
  ;; Not ":: claude": that is the zellij agent's buffer, which
  ;; `my/project-reattach-terminals' can still bring back, and claude-code-ide
  ;; kills any buffer already holding the name it starts in.
  (format "%s :: claude-ide%s"
          (file-name-nondirectory (directory-file-name directory))
          (if instance (concat ":" instance) "")))

(use-package! claude-code-ide
  :defer t
  :config
  ;; Never a side window: `my/project-terminals' places the agent itself
  (setq claude-code-ide-terminal-backend 'ghostel
        claude-code-ide-use-side-window nil
        claude-code-ide-buffer-name-function #'my/claude-ide-buffer-name)
  ;; Gives Claude xref, imenu, tree-sitter and project info over MCP
  (claude-code-ide-emacs-tools-setup))

(map! :leader
      :desc "Claude Code IDE menu" "o c" #'claude-code-ide-menu)

(defun my/project-claude-ide ()
  "Show the project's claude-code-ide session in the selected window.
Starts one when the project has none.  Of several, it shows the first,
unnamed one, or else the one used last; `claude-code-ide' starts more."
  (require 'claude-code-ide)
  (let* ((root (expand-file-name (project-root (project-current t))))
         (live (seq-filter (lambda (session)
                             (buffer-live-p
                              (claude-code-ide-mcp-session-buffer session)))
                           (claude-code-ide-mcp--sessions-for-project root)))
         (session (or (seq-find (lambda (session)
                                  (null (claude-code-ide-mcp-session-instance-name
                                         session)))
                                live)
                      (car (seq-sort-by
                            (lambda (session)
                              (or (claude-code-ide-mcp-session-last-used session)
                                  0))
                            #'> live)))))
    (if session
        (switch-to-buffer (claude-code-ide-mcp-session-buffer session))
      ;; claude-code-ide shows a new session with plain `display-buffer'
      ;; when side windows are off; this keeps it in the selected window.
      (let ((display-buffer-overriding-action '(display-buffer-same-window)))
        (claude-code-ide)))))

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
The shell runs in a zellij session that outlives Emacs: switching back to
a project, even after an Emacs crash, reattaches it.  So does an agent
other than claude.  Claude runs in claude-code-ide instead, which ties it
to Emacs: switching back shows the running session, and after a crash
`claude-code-ide-continue' picks the conversation back up."
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
    (if (equal my/project-agent "claude")
        (my/project-claude-ide)
      ;; Run by the session's shell rather than exec'd, so quitting the
      ;; agent leaves a usable shell instead of ending the session.
      (my/project-ghostel my/project-agent my/project-agent))
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

(defun my/open-org-workspace ()
  "Open workspace \"org\": Dired of `org-directory' beside a shell there.
The shell, buffer \"org :: shell\", runs in zellij session emacs-org-shell,
which has no project hash, so `my/project-reattach-terminals' never takes
it.  Does nothing if the workspace exists or the directory is missing.
Comes back to the workspace it started from."
  (let ((dir (expand-file-name org-directory))
        (origin (+workspace-current-name)))
    (when (and (file-directory-p dir)
               (not (+workspace-exists-p "org")))
      (+workspace-switch "org" t)
      ;; A new workspace starts on the fallback buffer; make sure it is the
      ;; only window before splitting.
      (delete-other-windows)
      (dired dir)
      (let ((dired-window (selected-window)))
        (select-window (split-window-right))
        (my/ghostel-session dir "org :: shell" "emacs-org-shell")
        (select-window dired-window))
      (+workspace-switch origin))))

(defun my/show-home-terminal (frame)
  "Put the ~/ terminal to the right of *scratch* in FRAME's main workspace.
Only when FRAME shows nothing but the fallback buffer there, so a frame
opened on a file, a later frame (Doom gives those a workspace of their
own), or a layout already arranged is left alone.  The terminal, buffer
\"~ :: shell\", runs in zellij session emacs-home-shell, which has no
project hash, so `my/project-reattach-terminals' never takes it.
Under the same condition, it also opens `my/open-org-workspace' behind
main, so only the first frame does."
  (when (frame-live-p frame)
    (with-selected-frame frame
      (when (and (bound-and-true-p persp-mode)
                 (equal (+workspace-current-name) +workspaces-main)
                 (one-window-p t)
                 (eq (window-buffer) (doom-fallback-buffer)))
        (let ((scratch-window (selected-window)))
          (select-window (split-window-right))
          (my/ghostel-session (expand-file-name "~/") "~ :: shell"
                              "emacs-home-shell")
          (select-window scratch-window))
        (my/open-org-workspace)))))

(defun my/show-home-terminal-soon-h ()
  "Run `my/show-home-terminal' on the selected frame once Emacs is idle."
  ;; Deferred so Doom has put the frame in its workspace and emacsclient has
  ;; shown the files it was given, both of which the check depends on.
  (run-at-time 0 nil #'my/show-home-terminal (selected-frame)))

;; A daemon has no frame at startup; each emacsclient frame comes later.
(add-hook (if (daemonp) 'server-after-make-frame-hook 'window-setup-hook)
          #'my/show-home-terminal-soon-h)
