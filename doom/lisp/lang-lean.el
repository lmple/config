;;; lisp/lang-lean.el -*- lexical-binding: t; -*-

;;; Lean 4
;; The Lean server sends workspace/inlayHint/refresh, which lsp-mode's request
;; dispatcher doesn't know and warns about on every re-elaboration. It still
;; replies nil (the correct response), so only the warning needs to go.
(after! lsp-mode
  (defadvice! my/lsp-ignore-inlay-hint-refresh-a (message &rest args)
    :before-until #'lsp-warn
    (and (equal message "Unknown request method: %s")
         (equal (car args) "workspace/inlayHint/refresh"))))
