;;; lisp/llm.el -*- lexical-binding: t; -*-

;;; LLM ────────────────────────────────────────────────────────────────────────
;; gptel talks to a local llama-server, run in router mode by the
;; llama-server@home or llama-server@work user service (systemd/, see README)
;; with that machine's presets (llama/home.ini or llama/work.ini), through
;; the OpenAI-compatible API it exposes. The model list comes from the server,
;; so the presets file is the only list to edit.
(defconst my/gptel-llama-host "localhost:9091"
  "Where llama-server listens, as set in systemd/llama-server@.service.")

(defconst my/gptel-llama-key-file "~/.config/llama-server/api-key"
  "File holding the API key llama-server requires (see README).
It is outside the repo, and outside ~/.config/llama, which links into it.")

;; Declared special so the `let' below binds it dynamically for url.el, even
;; when url-vars isn't loaded yet.
(defvar url-request-extra-headers)

(defun my/gptel-llama-key ()
  "Return the API key, the first line of `my/gptel-llama-key-file', or nil."
  (let ((file (expand-file-name my/gptel-llama-key-file)))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (string-trim (buffer-substring (point-min) (line-end-position)))))))

(defun my/gptel-llama-backend (models)
  "Register the llama-cpp gptel backend offering MODELS, a list of symbols.
Registering under the same name replaces the previous backend."
  (gptel-make-openai "llama-cpp"
    :stream t
    :protocol "http"
    :host my/gptel-llama-host
    ;; A function, so the key is read at each request, never stored in Emacs.
    :key (lambda ()
           (or (my/gptel-llama-key)
               (user-error "No llama-server API key in %s (see README)"
                           my/gptel-llama-key-file)))
    :models (mapcar (lambda (name) (list name :capabilities '(tool-use)))
                    models)))

(defun my/gptel-llama-server-models ()
  "Return llama-server's models as a list of (NAME . LOADED-P), or nil.
Nil means there is no API key, or the server couldn't be reached within a
second."
  (when-let* ((key (my/gptel-llama-key))
              (buffer (let ((url-request-extra-headers
                             `(("Authorization" . ,(concat "Bearer " key)))))
                        (ignore-errors
                          (url-retrieve-synchronously
                           (format "http://%s/v1/models" my/gptel-llama-host)
                           t t 1)))))
    (unwind-protect
        (with-current-buffer buffer
          (goto-char (point-min))
          (when (and (looking-at "HTTP/[0-9.]+ 200")
                     (re-search-forward "\r?\n\r?\n" nil t))
            (seq-keep
             (lambda (model)
               ;; The router also lists every GGUF in the Hugging Face cache
               ;; ("cache"), but only presets get the flags from llama/*.ini.
               ;; A server started on a single model has no "source" at all.
               (when (equal (gethash "source" model "preset") "preset")
                 (cons (intern (gethash "id" model))
                       (when-let* ((status (gethash "status" model)))
                         (equal (gethash "value" status) "loaded")))))
             (gethash "data" (json-parse-buffer)))))
      (kill-buffer buffer))))

(defun my/gptel-llama-sync-models (&rest _)
  "Offer in gptel the models the running llama-server has presets for.
If the current model isn't one of them (say, the other machine's), switch to
the loaded model, or else the first one. Runs before `gptel-menu', so the menu
always shows what the server offers; does nothing if the server is down."
  (interactive)
  (if-let* ((models (my/gptel-llama-server-models)))
      (let ((backend (my/gptel-llama-backend (mapcar #'car models))))
        ;; Leave a different backend picked in the menu alone.
        (when (equal (gptel-backend-name gptel-backend) "llama-cpp")
          (setq gptel-backend backend)
          (unless (assq gptel-model models)
            (setq gptel-model (car (or (rassq t models) (car models))))))
        (when (called-interactively-p 'interactive)
          (message "llama-server offers: %s"
                   (mapconcat (lambda (m) (symbol-name (car m))) models ", "))))
    (when (called-interactively-p 'interactive)
      (if (my/gptel-llama-key)
          (message "llama-server isn't reachable at %s" my/gptel-llama-host)
        (message "No llama-server API key in %s (see README)"
                 my/gptel-llama-key-file)))))

(after! gptel
  ;; Until the server answers, assume the home preset, so gptel still loads.
  (setq gptel-backend (my/gptel-llama-backend '(gemma-4-12b))
        gptel-model 'gemma-4-12b)
  (my/gptel-llama-sync-models)
  (advice-add 'gptel-menu :before #'my/gptel-llama-sync-models))
