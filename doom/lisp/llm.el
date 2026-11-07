;;; lisp/llm.el -*- lexical-binding: t; -*-

;;; LLM ────────────────────────────────────────────────────────────────────────
;; gptel talks to a local llama-server, run in router mode by the
;; llama-server@home or llama-server@work user service (systemd/, see README)
;; with that machine's presets (llama/home.ini or llama/work.ini), through
;; the OpenAI-compatible API it exposes. The model list comes from the server,
;; so the presets file is the only list to edit.
(defconst my/gptel-llama-host "localhost:8080"
  "Where llama-server listens, as set in systemd/llama-server@.service.")

(defun my/gptel-llama-backend (models)
  "Register the llama-cpp gptel backend offering MODELS, a list of symbols.
Registering under the same name replaces the previous backend."
  (gptel-make-openai "llama-cpp"
    :stream t
    :protocol "http"
    :host my/gptel-llama-host
    :models (mapcar (lambda (name) (list name :capabilities '(tool-use)))
                    models)))

(defun my/gptel-llama-server-models ()
  "Return llama-server's models as a list of (NAME . LOADED-P), or nil.
Nil means the server couldn't be reached within a second."
  (when-let* ((buffer (ignore-errors
                        (url-retrieve-synchronously
                         (format "http://%s/v1/models" my/gptel-llama-host)
                         t t 1))))
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
      (message "llama-server isn't reachable at %s" my/gptel-llama-host))))

(after! gptel
  ;; Until the server answers, assume the home preset, so gptel still loads.
  (setq gptel-backend (my/gptel-llama-backend '(gemma-4-12b))
        gptel-model 'gemma-4-12b)
  (my/gptel-llama-sync-models)
  (advice-add 'gptel-menu :before #'my/gptel-llama-sync-models))
