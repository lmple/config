;;; lisp/lang-js.el -*- lexical-binding: t; -*-

;;; JavaScript / TypeScript ────────────────────────────────────────────────────

(after! js2-mode
  (setq js2-basic-offset 2
        js-indent-level 2))

(after! typescript-mode
  (setq typescript-indent-level 2))

(after! apheleia
  ;; JS/TS — prettier
  (when (executable-find "prettier")
    (dolist (mode '(js-mode js-ts-mode typescript-mode typescript-ts-mode
                    tsx-ts-mode web-mode))
      (setf (alist-get mode apheleia-mode-alist) 'prettier))))
