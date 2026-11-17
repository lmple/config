;;; cli.el -*- lexical-binding: t; -*-

;; `doom sync --env' snapshots the environment of the shell it runs in, and
;; Emacs loads that snapshot at every start. Run from an Emacs terminal or a
;; Claude Code shell, it would persist that pane's variables into Emacs:
;; - MY_ZELLIJ_* would send every plain M-x ghostel into that pane's session,
;;   and ZELLIJ* would make zshrc take ghostel shells for zellij panes.
;; - The CLAUDE* markers are the ones lisp/terminals.el strips, and
;;   CLAUDE_CODE_MESSAGING_TOKEN is a live session token that would be
;;   written to disk.
;; Settings such as CLAUDE_CODE_DISABLE_* are not markers and stay.
(with-eval-after-load "doom-env"
  (dolist (regexp '("^MY_ZELLIJ_" "^ZELLIJ"
                    "^CLAUDECODE$" "^CLAUDE_PID$" "^CLAUDE_EFFORT$"
                    "^CLAUDE_CODE_\\(CHILD_SESSION\\|SESSION_ID\\|SESSION_ATTENDED\\|ENTRYPOINT\\|EXECPATH\\|MESSAGING_SOCKET\\|MESSAGING_TOKEN\\)$"))
    (add-to-list 'doom-env-deny regexp)))
