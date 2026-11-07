;;; lisp/documents.el -*- lexical-binding: t; -*-

;;; Org ────────────────────────────────────────────────────────────────────────
;; Doom turns these prompts off, which lets an untrusted .org file run code via
;; an elisp: link, C-c C-c, or export. Re-enable them; this runs after Doom's
;; org-load-hook setup, so it wins.
(after! org
  (setq org-confirm-babel-evaluate t
        org-link-elisp-confirm-function #'yes-or-no-p))

;; Doom picks maim/scrot/gnome-screenshot, which are X11 tools and capture
;; nothing useful on KDE Wayland. Spectacle's background region mode blocks
;; until a region is selected, so org-download-screenshot waits for the file.
;; scrot is still installed only to quiet doom doctor, which checks for it.
(after! org-download
  (when (executable-find "spectacle")
    (setq org-download-screenshot-method "spectacle --background --nonotify --region --output %s")))

;;; LaTeX ──────────────────────────────────────────────────────────────────────
;; Doom picks the first installed viewer from this list and evince comes before
;; pdf-tools by default; keep compiled PDFs (with SyncTeX) inside Emacs.
(setq +latex-viewers '(pdf-tools))

;; Org's default sends .pdf to the system app, bypassing pdf-tools.
(after! org
  (setf (alist-get "\\.pdf\\'" org-file-apps nil nil #'equal) 'emacs))
