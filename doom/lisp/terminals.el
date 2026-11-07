;;; lisp/terminals.el -*- lexical-binding: t; -*-

(map! :leader
      "o T" #'ghostel-project) ;; replace with your actual ghostty function

;; ghostel's own URL detection stops at newlines, including the ones it inserts
;; for soft wraps (marked `ghostel-wrap'), so a long URL opens truncated.
;; Dropping those newlines first rejoins it. Inside zellij this can't help:
;; zellij draws finished rows (zellij-org/zellij#3436), use its Alt u picker.
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

;; ghostel isn't loaded yet, so without this the `let's below would bind
;; `ghostel-buffer-name' lexically: ghostel would never see it, and its
;; defcustom errors when autoloaded inside such a binding.
(defvar ghostel-buffer-name)

(defvar my/project-claude-share 0.65
  "Fraction of the Claude/shell split that Claude's window gets.
The shell keeps the rest, which is still enough for a few commands.")

(defun my/project-terminals (&optional dir)
  "Pick a file in the project at DIR, then open Claude and a shell beside it.
DIR defaults to `default-directory'.  The file goes on the left, Claude
top-right and the shell bottom-right.  Cancelling the picker with
\\[keyboard-quit] skips the file and puts Claude and the shell side by side.
Either way Claude gets `my/project-claude-share' of the space it shares
with the shell.
Claude is only started in a newly created buffer, so switching back to a
project reuses its session."
  (interactive)
  (let* ((default-directory (or dir default-directory))
         (existing (buffer-list))
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
    ;; `ghostel-project' prefixes the name with the project, giving
    ;; *<project>-claude* and *<project>-shell*, and reuses them on later calls.
    (let ((claude (let ((ghostel-buffer-name "*claude*"))
                    (ghostel-project))))
      ;; Typed into the shell rather than exec'd, so quitting Claude leaves
      ;; a usable shell instead of killing the buffer.
      (unless (memq claude existing)
        (with-current-buffer claude
          (ghostel-send-string "claude\r"))))
    ;; Claude's window is still selected, and a positive SIZE goes to the
    ;; selected (top or left) window, so this sizes Claude, not the shell.
    (select-window
     (if file-window
         (split-window-below
          (round (* my/project-claude-share (window-total-height))))
       (split-window-right
        (round (* my/project-claude-share (window-total-width))))))
    (let ((ghostel-buffer-name "*shell*"))
      (ghostel-project))
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
