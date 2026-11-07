;;; lisp/lang-quint.el -*- lexical-binding: t; -*-

;;; Quint
;; The plugins come from a local quint checkout that isn't present on every
;; machine, so skip them instead of aborting startup when it's missing.
(let* ((quint-dir (expand-file-name "~/sources/quint/editor-plugins/emacs/"))
       (quint-mode-file (expand-file-name "quint-mode.el" quint-dir))
       (lsp-quint-file (expand-file-name "lsp-quint.el" quint-dir)))
  (when (file-exists-p quint-mode-file)
    (load quint-mode-file nil t)
    (add-to-list 'auto-mode-alist '("\\.qnt\\'" . quint-mode))
    ;; lsp-quint.el requires lsp-mode at load time, so defer it until lsp-mode
    ;; is loaded anyway instead of pulling it into startup.
    (after! lsp-mode
      (load lsp-quint-file nil t))
    ;; The server declares "." as a trigger character but answers only
    ;; requests marked as invoked, so lsp-mode's "."-triggered requests always
    ;; come back empty. Report them as invoked in Quint buffers.
    (defadvice! my/quint-lsp-completion-invoked-a (fn &rest args)
      :around #'lsp-completion--get-context
      (if (eq major-mode 'quint-mode)
          (let ((non-essential nil)) (apply fn args))
        (apply fn args)))
    ;; The server never completes plain names, so fall back to Quint's
    ;; keywords (reusing quint-mode.el's lists) and words from Quint buffers.
    (after! cape-keyword
      (add-to-list 'cape-keyword-list
                   (cons 'quint-mode (append quint-declarations quint-keywords
                                             quint-types quint-constants))))
    (add-hook! 'quint-mode-hook
      (defun my/quint-add-names-capf-h ()
        (add-hook 'completion-at-point-functions
                  (cape-capf-super #'cape-keyword #'cape-dabbrev) 20 t)))
    (add-hook 'quint-mode-local-vars-hook #'lsp! 'append)))
