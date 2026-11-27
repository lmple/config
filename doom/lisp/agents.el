;;; lisp/agents.el -*- lexical-binding: t; -*-

;; C-c o a: every coding agent, what it's doing and whether it waits for you,
;; with RET to jump to it.  Two sources, because the agents report in two
;; places:
;; - Emacs's Claude (claude-code-ide) talks straight to its ghostel buffer,
;;   which keeps the state Claude Code reports (OSC 7501) in
;;   `ghostel-program-status': working, blocked (a permission or a question),
;;   done, idle, with what it's doing.
;; - An agent in zellij (pi-local, opencode, cockpits) reports to zellij, which
;;   doesn't pass it on to the terminal around it.  waybar/agents.sh already
;;   reads zellij for the bar's agents pill, so its --json mode is reused here.

(require 'json)
(require 'tabulated-list)

;; Defined by ghostel, which loads later: declared so the reads below are of
;; the buffer-local values, not lexical bindings
(defvar ghostel-program-status)
(defvar ghostel-title)
(declare-function ghostel-buffer-list "ghostel")
;; Doom's :ui workspaces
(declare-function +workspace-list-names "autoload/workspaces")
(declare-function +workspace-switch "autoload/workspaces")
(declare-function +workspace-current-name "autoload/workspaces")
(defvar +workspaces-main)

(defvar my/agents-script (expand-file-name "~/.config/waybar/agents.sh")
  "The script that lists the agents in zellij, run with --json.
install.sh links waybar/ there.")

(defvar my/agents-refresh-seconds 3
  "Seconds between refreshes of the agents buffer while it is shown.")

(defconst my/agents-buffer-name "*agents*")

(defvar my/agents--zellij nil
  "The agents in zellij from the last `my/agents-script' run, as plists.")

(defvar my/agents--process nil
  "The running `my/agents-script', or nil.")

(defvar my/agents--timer nil
  "The timer refreshing the agents buffer while it exists.")

(defvar my/agents--render-pending nil
  "Non-nil while a render requested by a status change is scheduled.")

(defun my/agents--terminals ()
  "Return the ghostel buffers, none while ghostel isn't loaded."
  (and (fboundp 'ghostel-buffer-list) (ghostel-buffer-list)))

(defun my/agents--project (buffer)
  "Return the project of a \"<project> :: NAME\" BUFFER, or nil."
  ;; Greedy, like `my/terminal-role': a project name may hold \" :: \"
  (let ((name (buffer-name buffer)))
    (and (string-match "\\`\\(.*\\) :: .+\\'" name)
         (match-string 1 name))))

(defun my/agents--rank (state)
  "Return STATE's place in the list: what needs you first."
  (cond ((string-prefix-p "waiting" state) 0)
        ((member state '("done" "error")) 1)
        ((equal state "working") 2)
        (t 3)))

(defun my/agents--face (state)
  "Return the face STATE is shown in."
  (pcase (my/agents--rank state)
    (0 'error) (1 'success) (2 'warning) (_ 'shadow)))

(defun my/agents--claude-state (record)
  "Return the state shown for ghostel status RECORD, a plist or nil."
  (pcase (plist-get record :state)
    ('blocked (if-let* ((kind (plist-get record :kind)))
                  (format "waiting: %s" kind)
                "waiting"))
    ('working "working")
    ('done "done")
    ('error "error")
    (_ "idle")))

(defun my/agents--claude-rows ()
  "Return a row for every claude-code-ide session's buffer."
  (delq nil
        (mapcar
         (lambda (buffer)
           (when-let* ((role (my/terminal-role (buffer-name buffer)))
                       ((string-prefix-p "claude-ide" role)))
             (with-current-buffer buffer
               (let* ((record (cdr (assoc "" (bound-and-true-p
                                              ghostel-program-status))))
                      (msg (plist-get record :msg)))
                 (list :state (my/agents--claude-state record)
                       :workspace (my/agents--project buffer)
                       :agent role
                       ;; What it does, else the session's name
                       :task (if (and msg (not (string-empty-p msg)))
                                 msg
                               (or (bound-and-true-p ghostel-title) ""))
                       :buffer buffer)))))
         (my/agents--terminals))))

(defun my/agents--zellij-rows ()
  "Return a row for every agent in zellij, from `my/agents--zellij'."
  (mapcar
   (lambda (agent)
     (let* ((session (plist-get agent :session))
            (buffer (seq-find (lambda (buffer)
                                (equal (buffer-local-value 'my/zellij-session
                                                           buffer)
                                       session))
                              (my/agents--terminals)))
            (text (plist-get agent :text)))
       (list :state (plist-get agent :state)
             :workspace (or (and buffer (my/agents--project buffer)) session)
             :agent (plist-get agent :cmd)
             :task (if (and text (not (string-empty-p text)))
                       text
                     (or (plist-get agent :pane) ""))
             :buffer buffer
             :session session)))
   my/agents--zellij))

(defun my/agents--entries ()
  "Return the `tabulated-list-entries' of the agents buffer, sorted."
  (mapcar
   (lambda (row)
     (let ((state (plist-get row :state)))
       ;; The ID keeps point on the same agent across refreshes
       (list (list (plist-get row :buffer) (plist-get row :session))
             (vector (propertize state 'face (my/agents--face state))
                     (or (plist-get row :workspace) "")
                     (or (plist-get row :agent) "")
                     (plist-get row :task)))))
   (seq-sort-by (lambda (row) (my/agents--rank (plist-get row :state)))
                #'<
                (append (my/agents--claude-rows) (my/agents--zellij-rows)))))

(defun my/agents--render ()
  "Redraw the agents buffer, if it exists, from what is known now."
  (setq my/agents--render-pending nil)
  (when-let* ((buffer (get-buffer my/agents-buffer-name)))
    (with-current-buffer buffer
      (setq tabulated-list-entries (my/agents--entries))
      (tabulated-list-print t))))

(defun my/agents--fetch ()
  "Run `my/agents-script' in the background, then redraw.
Asynchronous, since it asks every zellij session in turn: Emacs never
waits on it.  A failed run keeps the previous list."
  (when (and (file-executable-p my/agents-script)
             (not (process-live-p my/agents--process)))
    (let ((out (generate-new-buffer " *agents.sh*"))
          (err (generate-new-buffer " *agents.sh stderr*")))
      (setq my/agents--process
            (make-process
             :name "agents.sh"
             :buffer out
             ;; Apart, so a warning can't break the JSON
             :stderr err
             :command (list my/agents-script "--json")
             :connection-type 'pipe
             :noquery t
             :sentinel
             (lambda (process _event)
               (unless (process-live-p process)
                 (unwind-protect
                     (when (zerop (process-exit-status process))
                       (with-current-buffer out
                         (goto-char (point-min))
                         (setq my/agents--zellij
                               (condition-case nil
                                   (json-parse-buffer :object-type 'plist
                                                      :array-type 'list)
                                 (json-error my/agents--zellij)))))
                   (kill-buffer out)
                   (kill-buffer err))
                 (my/agents--render))))))))

(defun my/agents-refresh ()
  "Refresh the agents buffer: Emacs's agents now, zellij's when it answers."
  (interactive)
  (my/agents--render)
  (my/agents--fetch))

(defun my/agents--tick ()
  "Refresh the agents buffer while it is shown; stop once it is gone."
  (cond ((not (get-buffer my/agents-buffer-name))
         (cancel-timer my/agents--timer)
         (setq my/agents--timer nil))
        ((get-buffer-window my/agents-buffer-name t)
         (my/agents-refresh))))

(defun my/agents--status-changed (_id _old _new)
  "Redraw the shown agents buffer soon after a terminal's status changes.
On `ghostel-program-status-functions', which runs on terminal output, so
this only schedules one redraw, however many changes come in."
  (when (and (not my/agents--render-pending)
             (get-buffer-window my/agents-buffer-name t))
    (setq my/agents--render-pending t)
    (run-with-idle-timer 0.2 nil #'my/agents--render)))

;; After ghostel-status: adding to its hook before the defcustom runs would
;; replace the hook's default functions, the mode line and notifications.
(with-eval-after-load 'ghostel-status
  (add-hook 'ghostel-program-status-functions #'my/agents--status-changed))

(defun my/agents-visit ()
  "Jump to the agent on this line, in its project's workspace.
Doom names a project's workspace after it, as the terminals' buffers are.
An agent with no buffer in Emacs only says where it runs."
  (interactive)
  (pcase-let ((`(,buffer ,session) (or (tabulated-list-get-id)
                                       (user-error "No agent on this line"))))
    (if (not (buffer-live-p buffer))
        (message "This agent runs in zellij session %s, outside Emacs" session)
      (let ((workspace (my/agents--project buffer)))
        ;; main keeps the list on screen. Anywhere else it was shown for the
        ;; jump only, so it goes, and the layout left behind doesn't keep it.
        (unless (equal (+workspace-current-name) +workspaces-main)
          (quit-window))
        (when (and workspace (member workspace (+workspace-list-names)))
          (+workspace-switch workspace))
        (if-let* ((window (get-buffer-window buffer)))
            (select-window window)
          (switch-to-buffer buffer))))))

(defvar-keymap my/agents-mode-map
  :parent tabulated-list-mode-map
  "RET" #'my/agents-visit)

(define-derived-mode my/agents-mode tabulated-list-mode "Agents"
  "The coding agents, what they're doing, and which wait for you.
\\<my/agents-mode-map>\\[my/agents-visit] jumps to one, \\[revert-buffer] refreshes now."
  (setq tabulated-list-format [("State" 16 nil)
                               ("Workspace" 18 nil)
                               ("Agent" 12 nil)
                               ("Task" 0 nil)]
        tabulated-list-padding 1
        ;; Already in order: what needs you first
        tabulated-list-sort-key nil)
  (setq-local revert-buffer-function (lambda (&rest _) (my/agents-refresh)))
  (tabulated-list-init-header))

(defun my/agents-buffer ()
  "Return the agents buffer, created and refreshing, its list up to date.
Refreshed every `my/agents-refresh-seconds' while it is shown."
  (let ((buffer (get-buffer-create my/agents-buffer-name)))
    (with-current-buffer buffer
      (unless (derived-mode-p 'my/agents-mode)
        (my/agents-mode)))
    (unless (timerp my/agents--timer)
      (setq my/agents--timer (run-at-time my/agents-refresh-seconds
                                          my/agents-refresh-seconds
                                          #'my/agents--tick)))
    (my/agents-refresh)
    buffer))

(defun my/agents-show-above (window)
  "Show the agents list in a new window above WINDOW, and return it."
  (let ((agents (split-window window nil 'above)))
    (set-window-buffer agents (my/agents-buffer))
    agents))

(defun my/agents ()
  "Go to the agents list in the main workspace.
Every coding agent, its state and what it's doing: Emacs's Claude
sessions and the agents in zellij.  The list sits above main's ~ shell
\(`my/show-home-terminal'); closed there, it comes back above the shell,
or in the selected window when the shell isn't shown either."
  (interactive)
  (let ((buffer (my/agents-buffer)))
    (unless (equal (+workspace-current-name) +workspaces-main)
      (+workspace-switch +workspaces-main t))
    (select-window
     (or (get-buffer-window buffer)
         (when-let* ((shell (get-buffer-window "~ :: shell")))
           (my/agents-show-above shell))
         (progn (switch-to-buffer buffer) (selected-window))))))

(map! :leader
      :desc "Agents" "o a" #'my/agents)
