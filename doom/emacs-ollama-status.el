;;; emacs-ollama-status.el --- Display Ollama model status in Emacs -*- lexical-binding: t -*-

;;; Commentary:
;; A simple Emacs plugin to show available Ollama models.
;; Queries the local Ollama API (http://localhost:11434) to list models.

;;; Code:

(defgroup emacs-ollama-status nil
  "Display Ollama model status."
  :group 'tools)

(defcustom emacs-ollama-status-host "http://localhost:11434"
  "Ollama API host URL."
  :type 'string
  :group 'emacs-ollama-status)

(defcustom emacs-ollama-status-refresh-interval 60
  "Refresh interval in seconds for automatic model list update."
  :type 'integer
  :group 'emacs-ollama-status)

(defvar emacs-ollama-status--models nil
  "List of currently available Ollama models.")

(defvar emacs-ollama-status--timer nil
  "Timer for automatic refresh.")

(defvar emacs-ollama-status-mode-line-string ""
  "Modeline string showing Ollama status.")

(defun emacs-ollama-status--fetch-models ()
  "Fetch the list of models from Ollama API."
  (condition-case err
      (let ((url (concat emacs-ollama-status-host "/api/tags"))
            (url-request-method "GET"))
        (with-current-buffer
            (url-retrieve-synchronously url t)
          (goto-char (point-min))
          (re-search-forward "\n\n" nil t)
          (let* ((json-array-type 'list)
                 (json (json-parse-buffer :object-type 'alist))
                 (models (alist-get 'models json)))
            (setq emacs-ollama-status--models
                  (mapcar (lambda (m)
                            (alist-get 'name m))
                          models))
            (setq emacs-ollama-status-mode-line-string
                  (if emacs-ollama-status--models
                      (format " Ollama:%s "
                              (string-join emacs-ollama-status--models ","))
                    " Ollama:offline ")))
          (kill-buffer (current-buffer))))
    (error
     (setq emacs-ollama-status-mode-line-string " Ollama:offline ")
     nil)))

(defun emacs-ollama-status-refresh ()
  "Manually refresh the model list."
  (interactive)
  (emacs-ollama-status--fetch-models)
  (force-mode-line-update))

(defun emacs-ollama-status-start ()
  "Start automatic model list refresh."
  (when emacs-ollama-status--timer
    (cancel-timer emacs-ollama-status--timer))
  (emacs-ollama-status--fetch-models)
  (setq emacs-ollama-status--timer
        (run-at-time t emacs-ollama-status-refresh-interval
                     'emacs-ollama-status-refresh)))

(defun emacs-ollama-status-stop ()
  "Stop automatic model list refresh."
  (interactive)
  (when emacs-ollama-status--timer
    (cancel-timer emacs-ollama-status--timer)
    (setq emacs-ollama-status--timer nil))
  (setq emacs-ollama-status-mode-line-string ""))

(defun emacs-ollama-status-list-models ()
  "Display the list of available Ollama models in a buffer."
  (interactive)
  (emacs-ollama-status--fetch-models)
  (let ((buf (get-buffer-create "*Ollama Models*")))
    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert "Ollama Models\n")
      (insert (make-string 14 ?-) "\n\n")
      (if emacs-ollama-status--models
          (dolist (model emacs-ollama-status--models)
            (insert (format "  • %s\n" model)))
        (insert "  (none available or Ollama offline)\n"))
      (insert "\n")
      (insert (format "Host: %s\n" emacs-ollama-status-host))
      (insert (format "Last checked: %s\n" (format-time-string "%H:%M:%S")))
      (goto-char (point-min))
      (setq buffer-read-only t)
      (display-buffer buf)))
  (emacs-ollama-status-start))

(add-to-list 'global-mode-string 'emacs-ollama-status-mode-line-string t)

;;;###autoload
(define-minor-mode emacs-ollama-status-mode
  "Toggle Ollama model status display."
  :lighter ""
  (if emacs-ollama-status-mode
      (emacs-ollama-status-start)
    (emacs-ollama-status-stop)))

(provide 'emacs-ollama-status)

;;; emacs-ollama-status.el ends here
