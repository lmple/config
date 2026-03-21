;;; mario-nes-theme.el --- A dark Emacs theme inspired by Super Mario Bros NES

;; Author: Loïc Lièvre
;; Version: 1.1.0
;; Package-Requires: ((emacs "28.1"))
;; Keywords: themes, dark, retro, NES, Mario

;;; Commentary:
;; A dark theme drawing its palette directly from the NES Super Mario Bros
;; color set: the pure black void of World 3-1's night sky, Mario's brick
;; browns and reds, coin gold, pipe greens, cloud whites, and Goomba tans.
;;
;; Covers: font-lock, doom-modeline, treemacs (full), magit, org, diff,
;;         company, corfu, vertico, consult, marginalia, transient,
;;         solaire-mode, tab-bar, winum/ace-window, lsp/eglot, flycheck.
;;
;; INSTALLATION — Doom Emacs (no evil mode):
;;
;;   1. mkdir -p ~/.doom.d/themes
;;      cp mario-nes-theme.el ~/.doom.d/themes/
;;
;;   2. ~/.doom.d/config.el:
;;        (setq doom-theme 'mario-nes)
;;
;;   3. Optional – silence "unknown theme" byte-compile warnings.
;;      ~/.doom.d/packages.el:
;;        (package! mario-nes-theme
;;          :recipe (:local-repo "themes" :no-byte-compile t))
;;
;;   4. doom sync  →  restart or M-x doom/reload
;;
;; TREEMACS integration:
;;   Works automatically.  If you use doom-themes' treemacs icons, add:
;;     (after! doom-themes
;;       (doom-themes-treemacs-config))
;;   The faces here override doom-themes defaults while keeping its icons.

;;; Code:

(unless (>= emacs-major-version 28)
  (error "mario-nes-theme requires Emacs 28 or later"))

(deftheme mario-nes "Dark theme inspired by Super Mario Bros NES palette.")

;;; ---------------------------------------------------------------------------
;;; Palette — extracted from authentic NES NTSC color output
;;; ---------------------------------------------------------------------------
(let* (
  ;; Backgrounds
  (nes-void       "#0B0B0B")   ;; NES pure black — the night sky
  (nes-bg-alt     "#151515")   ;; slightly lifted background
  (nes-bg-ui      "#1C1C1C")   ;; modeline / fringe / panels
  (nes-selection  "#2B1A0A")   ;; warm dark brown selection
  (nes-highlight  "#3A2210")   ;; slightly brighter selection/highlight

  ;; Foreground
  (nes-fg         "#E8DCC8")   ;; warm off-white — cloud / HUD text
  (nes-fg-dim     "#9A8A72")   ;; dimmed text / comments
  (nes-fg-faint   "#4A3E30")   ;; very dim — line numbers, subtle UI

  ;; Mario red & skin
  (nes-mario-red  "#D03000")   ;; Mario's hat and shirt — NES red-orange
  (nes-mario-skin "#E89850")   ;; Mario's face / overalls highlight
  (nes-mario-dark "#8B3A10")   ;; Mario's dark brown outline

  ;; Coin & star gold
  (nes-coin-gold  "#F8B800")   ;; coin / star yellow-gold
  (nes-coin-light "#FFD860")   ;; bright coin shine

  ;; Pipe & vine green
  (nes-pipe-green "#00A800")   ;; warp pipe green
  (nes-pipe-dark  "#005000")   ;; pipe shadow / deep green

  ;; Sky & water blue
  (nes-sky-blue   "#5090D0")   ;; NES sky / cloud outline
  (nes-water-blue "#0058F8")   ;; NES water / underwater level blue

  ;; Brick & ground brown
  (nes-brick      "#C04000")   ;; brick block brown
  (nes-ground     "#A84000")   ;; ground platform brown
  (nes-block-tan  "#D89050")   ;; question block tan / mystery block

  ;; Goomba & enemy
  (nes-goomba     "#A05000")   ;; Goomba body brown
  (nes-mushroom   "#F03000")   ;; red mushroom cap

  ;; Extras
  (nes-piranha    "#00C000")   ;; piranha plant bright green
  (nes-error      "#D00040")   ;; error / warning red-pink
  (nes-string-tan "#D8A060")   ;; string / literal warm tan
  )

  (custom-theme-set-faces
   'mario-nes

   ;; -------------------------------------------------------------------------
   ;; Core UI
   ;; -------------------------------------------------------------------------
   `(default                          ((t (:background ,nes-void :foreground ,nes-fg))))
   `(cursor                           ((t (:background ,nes-coin-gold))))
   `(fringe                           ((t (:background ,nes-bg-ui :foreground ,nes-fg-faint))))
   `(border                           ((t (:foreground ,nes-fg-faint))))
   `(vertical-border                  ((t (:foreground ,nes-fg-faint))))
   `(window-divider                   ((t (:foreground ,nes-fg-faint))))
   `(window-divider-first-pixel       ((t (:foreground ,nes-fg-faint))))
   `(window-divider-last-pixel        ((t (:foreground ,nes-fg-faint))))
   `(hl-line                          ((t (:background ,nes-highlight))))
   `(region                           ((t (:background ,nes-selection))))
   `(secondary-selection              ((t (:background ,nes-highlight))))
   `(highlight                        ((t (:background ,nes-highlight :foreground ,nes-coin-gold))))
   `(match                            ((t (:background ,nes-pipe-dark :foreground ,nes-pipe-green :weight bold))))
   `(lazy-highlight                   ((t (:background ,nes-bg-ui :foreground ,nes-coin-light :box (:line-width -1 :color ,nes-coin-gold)))))
   `(isearch                          ((t (:background ,nes-coin-gold :foreground ,nes-void :weight bold))))
   `(isearch-fail                     ((t (:background ,nes-error :foreground ,nes-fg))))

   ;; -------------------------------------------------------------------------
   ;; Mode line
   ;; -------------------------------------------------------------------------
   `(mode-line                        ((t (:background ,nes-mario-red :foreground ,nes-fg :box nil :weight bold))))
   `(mode-line-inactive               ((t (:background ,nes-bg-ui :foreground ,nes-fg-dim :box nil))))
   `(mode-line-buffer-id              ((t (:foreground ,nes-coin-gold :weight bold))))
   `(mode-line-emphasis               ((t (:foreground ,nes-coin-light :weight bold))))
   `(mode-line-highlight              ((t (:foreground ,nes-mario-skin :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Minibuffer & echo area
   ;; -------------------------------------------------------------------------
   `(minibuffer-prompt                ((t (:foreground ,nes-coin-gold :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Line numbers
   ;; -------------------------------------------------------------------------
   `(line-number                      ((t (:background ,nes-void :foreground ,nes-fg-faint))))
   `(line-number-current-line         ((t (:background ,nes-bg-ui :foreground ,nes-coin-gold :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Font lock — syntax highlighting
   ;; -------------------------------------------------------------------------

   ;; Comments → Goomba brown / dim tan  (like the tan enemies lurking in dim areas)
   `(font-lock-comment-face           ((t (:foreground ,nes-fg-dim :slant italic))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,nes-fg-faint :slant italic))))
   `(font-lock-doc-face               ((t (:foreground ,nes-goomba :slant italic))))

   ;; Strings → warm block tan / coin area (Mario's reward)
   `(font-lock-string-face            ((t (:foreground ,nes-string-tan))))
   `(font-lock-doc-string-face        ((t (:foreground ,nes-block-tan))))

   ;; Keywords → Mario red (prominent, impossible to miss)
   `(font-lock-keyword-face           ((t (:foreground ,nes-mario-red :weight bold))))

   ;; Built-ins → pipe green (structural, environmental)
   `(font-lock-builtin-face           ((t (:foreground ,nes-pipe-green))))

   ;; Constants → coin gold (precious, immutable values)
   `(font-lock-constant-face          ((t (:foreground ,nes-coin-gold))))

   ;; Types → sky blue (structural backdrop)
   `(font-lock-type-face              ((t (:foreground ,nes-sky-blue))))

   ;; Function names → Mario skin / warm orange (the protagonist's actions)
   `(font-lock-function-name-face     ((t (:foreground ,nes-mario-skin :weight bold))))

   ;; Variable names → cloud white / off-white (ubiquitous, everywhere)
   `(font-lock-variable-name-face     ((t (:foreground ,nes-fg))))

   ;; Preprocessor / macros → piranha plant green (dangerous, special)
   `(font-lock-preprocessor-face      ((t (:foreground ,nes-piranha :weight bold))))

   ;; Warnings / negation → mushroom red
   `(font-lock-warning-face           ((t (:foreground ,nes-mushroom :weight bold))))

   ;; Regexp grouping
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,nes-coin-light :weight bold))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,nes-coin-gold  :weight bold))))

   ;; Delimiters
   `(font-lock-delimiter-face         ((t (:foreground ,nes-fg-dim))))
   `(font-lock-operator-face          ((t (:foreground ,nes-mario-skin))))
   `(font-lock-number-face            ((t (:foreground ,nes-coin-light))))
   `(font-lock-property-name-face     ((t (:foreground ,nes-sky-blue))))
   `(font-lock-property-use-face      ((t (:foreground ,nes-sky-blue :slant italic))))
   `(font-lock-punctuation-face       ((t (:foreground ,nes-fg-dim))))
   `(font-lock-escape-face            ((t (:foreground ,nes-coin-gold :weight bold))))
   `(font-lock-misc-punctuation-face  ((t (:foreground ,nes-fg-dim))))

   ;; -------------------------------------------------------------------------
   ;; Parentheses / rainbow-delimiters
   ;; -------------------------------------------------------------------------
   `(rainbow-delimiters-depth-1-face  ((t (:foreground ,nes-coin-gold))))
   `(rainbow-delimiters-depth-2-face  ((t (:foreground ,nes-pipe-green))))
   `(rainbow-delimiters-depth-3-face  ((t (:foreground ,nes-sky-blue))))
   `(rainbow-delimiters-depth-4-face  ((t (:foreground ,nes-mario-skin))))
   `(rainbow-delimiters-depth-5-face  ((t (:foreground ,nes-mario-red))))
   `(rainbow-delimiters-depth-6-face  ((t (:foreground ,nes-piranha))))
   `(rainbow-delimiters-depth-7-face  ((t (:foreground ,nes-coin-light))))
   `(rainbow-delimiters-depth-8-face  ((t (:foreground ,nes-block-tan))))
   `(rainbow-delimiters-depth-9-face  ((t (:foreground ,nes-mushroom))))
   `(rainbow-delimiters-unmatched-face ((t (:foreground ,nes-error :weight bold :underline t))))
   `(rainbow-delimiters-mismatched-face ((t (:foreground ,nes-error :weight bold :underline t))))

   ;; -------------------------------------------------------------------------
   ;; show-paren
   ;; -------------------------------------------------------------------------
   `(show-paren-match                 ((t (:background ,nes-pipe-dark :foreground ,nes-coin-gold :weight bold))))
   `(show-paren-mismatch              ((t (:background ,nes-error :foreground ,nes-fg :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Links & buttons
   ;; -------------------------------------------------------------------------
   `(link                             ((t (:foreground ,nes-sky-blue :underline t))))
   `(link-visited                     ((t (:foreground ,nes-water-blue :underline t))))
   `(button                           ((t (:foreground ,nes-coin-gold :underline t))))

   ;; -------------------------------------------------------------------------
   ;; Dired
   ;; -------------------------------------------------------------------------
   `(dired-directory                  ((t (:foreground ,nes-sky-blue :weight bold))))
   `(dired-symlink                    ((t (:foreground ,nes-piranha))))
   `(dired-marked                     ((t (:foreground ,nes-coin-gold :weight bold))))
   `(dired-flagged                    ((t (:foreground ,nes-error :weight bold))))
   `(dired-header                     ((t (:foreground ,nes-mario-red :weight bold))))
   `(dired-ignored                    ((t (:foreground ,nes-fg-faint))))

   ;; -------------------------------------------------------------------------
   ;; Org mode
   ;; -------------------------------------------------------------------------
   `(org-level-1                      ((t (:foreground ,nes-mario-red    :weight bold :height 1.3))))
   `(org-level-2                      ((t (:foreground ,nes-coin-gold    :weight bold :height 1.2))))
   `(org-level-3                      ((t (:foreground ,nes-pipe-green   :weight bold :height 1.1))))
   `(org-level-4                      ((t (:foreground ,nes-sky-blue     :weight bold))))
   `(org-level-5                      ((t (:foreground ,nes-mario-skin   :weight bold))))
   `(org-level-6                      ((t (:foreground ,nes-block-tan    :weight bold))))
   `(org-level-7                      ((t (:foreground ,nes-piranha      :weight bold))))
   `(org-level-8                      ((t (:foreground ,nes-mushroom     :weight bold))))
   `(org-todo                         ((t (:foreground ,nes-mario-red :weight bold))))
   `(org-done                         ((t (:foreground ,nes-pipe-green :weight bold :strike-through t))))
   `(org-headline-done                ((t (:foreground ,nes-fg-dim :strike-through t))))
   `(org-date                         ((t (:foreground ,nes-sky-blue :underline t))))
   `(org-link                         ((t (:foreground ,nes-sky-blue :underline t))))
   `(org-tag                          ((t (:foreground ,nes-coin-gold :weight bold))))
   `(org-code                         ((t (:foreground ,nes-block-tan :background ,nes-bg-ui))))
   `(org-verbatim                     ((t (:foreground ,nes-piranha))))
   `(org-block                        ((t (:background ,nes-bg-alt :extend t))))
   `(org-block-begin-line             ((t (:foreground ,nes-fg-faint :background ,nes-bg-ui :extend t))))
   `(org-block-end-line               ((t (:foreground ,nes-fg-faint :background ,nes-bg-ui :extend t))))
   `(org-table                        ((t (:foreground ,nes-sky-blue))))
   `(org-special-keyword              ((t (:foreground ,nes-goomba))))
   `(org-meta-line                    ((t (:foreground ,nes-fg-faint))))
   `(org-document-title               ((t (:foreground ,nes-coin-gold :weight bold :height 1.5))))
   `(org-document-info                ((t (:foreground ,nes-fg-dim))))
   `(org-checkbox                     ((t (:foreground ,nes-coin-gold :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Magit
   ;; -------------------------------------------------------------------------
   `(magit-branch-local               ((t (:foreground ,nes-pipe-green :weight bold))))
   `(magit-branch-remote              ((t (:foreground ,nes-sky-blue :weight bold))))
   `(magit-tag                        ((t (:foreground ,nes-coin-gold :weight bold))))
   `(magit-hash                       ((t (:foreground ,nes-fg-dim))))
   `(magit-section-heading            ((t (:foreground ,nes-mario-red :weight bold))))
   `(magit-section-highlight          ((t (:background ,nes-bg-alt))))
   `(magit-diff-added                 ((t (:background "#0A2A0A" :foreground ,nes-pipe-green))))
   `(magit-diff-added-highlight       ((t (:background "#102A10" :foreground ,nes-piranha))))
   `(magit-diff-removed               ((t (:background "#2A0A0A" :foreground ,nes-mushroom))))
   `(magit-diff-removed-highlight     ((t (:background "#2A1010" :foreground ,nes-error))))
   `(magit-diff-context               ((t (:foreground ,nes-fg-dim))))
   `(magit-diff-context-highlight     ((t (:background ,nes-bg-alt :foreground ,nes-fg-dim))))
   `(magit-diff-hunk-heading          ((t (:background ,nes-bg-ui :foreground ,nes-sky-blue))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,nes-highlight :foreground ,nes-sky-blue :weight bold))))
   `(magit-log-author                 ((t (:foreground ,nes-mario-skin))))
   `(magit-log-date                   ((t (:foreground ,nes-fg-dim))))

   ;; -------------------------------------------------------------------------
   ;; Flycheck / Flymake
   ;; -------------------------------------------------------------------------
   `(flycheck-error                   ((t (:underline (:color ,nes-error :style wave)))))
   `(flycheck-warning                 ((t (:underline (:color ,nes-coin-gold :style wave)))))
   `(flycheck-info                    ((t (:underline (:color ,nes-sky-blue :style wave)))))
   `(flymake-error                    ((t (:underline (:color ,nes-error :style wave)))))
   `(flymake-warning                  ((t (:underline (:color ,nes-coin-gold :style wave)))))
   `(flymake-note                     ((t (:underline (:color ,nes-sky-blue :style wave)))))

   ;; -------------------------------------------------------------------------
   ;; Company / Corfu completion
   ;; -------------------------------------------------------------------------
   `(company-tooltip                  ((t (:background ,nes-bg-ui :foreground ,nes-fg))))
   `(company-tooltip-common           ((t (:foreground ,nes-coin-gold :weight bold))))
   `(company-tooltip-selection        ((t (:background ,nes-selection :foreground ,nes-fg))))
   `(company-tooltip-annotation       ((t (:foreground ,nes-fg-dim))))
   `(company-scrollbar-bg             ((t (:background ,nes-bg-alt))))
   `(company-scrollbar-fg             ((t (:background ,nes-mario-red))))
   `(corfu-default                    ((t (:background ,nes-bg-ui :foreground ,nes-fg))))
   `(corfu-current                    ((t (:background ,nes-selection :foreground ,nes-coin-gold :weight bold))))
   `(corfu-bar                        ((t (:background ,nes-mario-red))))
   `(corfu-border                     ((t (:background ,nes-fg-faint))))
   `(corfu-annotations                ((t (:foreground ,nes-fg-dim))))

   ;; -------------------------------------------------------------------------
   ;; Vertico / Selectrum / Ivy / Helm
   ;; -------------------------------------------------------------------------
   `(vertico-current                  ((t (:background ,nes-selection :foreground ,nes-coin-gold :weight bold))))
   `(ivy-current-match                ((t (:background ,nes-selection :foreground ,nes-coin-gold :weight bold))))
   `(ivy-minibuffer-match-face-1      ((t (:foreground ,nes-coin-gold :weight bold))))
   `(ivy-minibuffer-match-face-2      ((t (:foreground ,nes-pipe-green :weight bold))))
   `(ivy-minibuffer-match-face-3      ((t (:foreground ,nes-mario-skin :weight bold))))
   `(ivy-minibuffer-match-face-4      ((t (:foreground ,nes-sky-blue :weight bold))))
   `(helm-selection                   ((t (:background ,nes-selection :foreground ,nes-coin-gold))))
   `(helm-match                       ((t (:foreground ,nes-coin-gold :weight bold))))
   `(helm-source-header               ((t (:background ,nes-mario-red :foreground ,nes-fg :weight bold :height 1.1))))

   ;; -------------------------------------------------------------------------
   ;; LSP / Eglot
   ;; -------------------------------------------------------------------------
   `(eglot-highlight-symbol-face      ((t (:background ,nes-highlight))))
   `(lsp-face-highlight-textual       ((t (:background ,nes-highlight))))
   `(lsp-face-highlight-read          ((t (:background ,nes-selection))))
   `(lsp-face-highlight-write         ((t (:background "#2A1A05" :underline t))))

   ;; -------------------------------------------------------------------------
   ;; Tree-sitter (Emacs 29+)
   ;; -------------------------------------------------------------------------
   `(treesit-font-lock-face           ((t (:inherit default))))

   ;; -------------------------------------------------------------------------
   ;; Which-key
   ;; -------------------------------------------------------------------------
   `(which-key-key-face               ((t (:foreground ,nes-coin-gold :weight bold))))
   `(which-key-command-description-face ((t (:foreground ,nes-fg))))
   `(which-key-group-description-face ((t (:foreground ,nes-pipe-green :weight bold))))
   `(which-key-separator-face         ((t (:foreground ,nes-fg-faint))))

   ;; -------------------------------------------------------------------------
   ;; Diff / Ediff
   ;; -------------------------------------------------------------------------
   `(diff-added                       ((t (:background "#0A200A" :foreground ,nes-pipe-green))))
   `(diff-removed                     ((t (:background "#200A0A" :foreground ,nes-mushroom))))
   `(diff-changed                     ((t (:background "#1A1500" :foreground ,nes-coin-gold))))
   `(diff-header                      ((t (:background ,nes-bg-ui :foreground ,nes-mario-red :weight bold))))
   `(diff-file-header                 ((t (:background ,nes-bg-ui :foreground ,nes-fg :weight bold))))
   `(diff-hunk-header                 ((t (:background ,nes-bg-alt :foreground ,nes-sky-blue))))

   ;; -------------------------------------------------------------------------
   ;; Error / success / warning messages
   ;; -------------------------------------------------------------------------
   `(error                            ((t (:foreground ,nes-error :weight bold))))
   `(warning                          ((t (:foreground ,nes-coin-gold :weight bold))))
   `(success                          ((t (:foreground ,nes-pipe-green :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Pulse / Beacon
   ;; -------------------------------------------------------------------------
   `(pulse-highlight-start-face       ((t (:background ,nes-coin-gold))))

   ;; -------------------------------------------------------------------------
   ;; Term / Shell / Eshell
   ;; -------------------------------------------------------------------------
   `(term-color-black                 ((t (:foreground ,nes-void))))
   `(term-color-red                   ((t (:foreground ,nes-mario-red))))
   `(term-color-green                 ((t (:foreground ,nes-pipe-green))))
   `(term-color-yellow                ((t (:foreground ,nes-coin-gold))))
   `(term-color-blue                  ((t (:foreground ,nes-water-blue))))
   `(term-color-magenta               ((t (:foreground ,nes-mushroom))))
   `(term-color-cyan                  ((t (:foreground ,nes-sky-blue))))
   `(term-color-white                 ((t (:foreground ,nes-fg))))
   `(eshell-prompt                    ((t (:foreground ,nes-coin-gold :weight bold))))
   `(eshell-ls-directory              ((t (:foreground ,nes-sky-blue :weight bold))))
   `(eshell-ls-symlink                ((t (:foreground ,nes-piranha))))
   `(eshell-ls-executable             ((t (:foreground ,nes-pipe-green :weight bold))))
   `(eshell-ls-missing                ((t (:foreground ,nes-error))))

   ;; -------------------------------------------------------------------------
   ;; Markdown
   ;; -------------------------------------------------------------------------
   `(markdown-header-face-1           ((t (:foreground ,nes-mario-red    :weight bold :height 1.3))))
   `(markdown-header-face-2           ((t (:foreground ,nes-coin-gold    :weight bold :height 1.2))))
   `(markdown-header-face-3           ((t (:foreground ,nes-pipe-green   :weight bold :height 1.1))))
   `(markdown-code-face               ((t (:background ,nes-bg-alt :foreground ,nes-block-tan))))
   `(markdown-inline-code-face        ((t (:background ,nes-bg-ui :foreground ,nes-block-tan))))
   `(markdown-link-face               ((t (:foreground ,nes-sky-blue :underline t))))
   `(markdown-url-face                ((t (:foreground ,nes-water-blue :underline t))))
   `(markdown-bold-face               ((t (:weight bold :foreground ,nes-fg))))
   `(markdown-italic-face             ((t (:slant italic :foreground ,nes-fg-dim))))
   `(markdown-list-face               ((t (:foreground ,nes-coin-gold))))

   ;; -------------------------------------------------------------------------
   ;; Doom Emacs specific (since you use Doom without evil mode)
   ;; -------------------------------------------------------------------------
   `(doom-modeline-bar                ((t (:background ,nes-mario-red))))
   `(doom-modeline-bar-inactive       ((t (:background ,nes-bg-ui))))
   `(doom-modeline-buffer-file        ((t (:foreground ,nes-coin-gold :weight bold))))
   `(doom-modeline-buffer-modified    ((t (:foreground ,nes-mario-skin :weight bold))))
   `(doom-modeline-buffer-path        ((t (:foreground ,nes-fg-dim))))
   `(doom-modeline-project-dir        ((t (:foreground ,nes-pipe-green :weight bold))))
   `(doom-modeline-error              ((t (:foreground ,nes-error))))
   `(doom-modeline-warning            ((t (:foreground ,nes-coin-gold))))
   `(doom-modeline-info               ((t (:foreground ,nes-sky-blue))))
   `(doom-modeline-lsp-success        ((t (:foreground ,nes-pipe-green))))
   `(doom-modeline-lsp-warning        ((t (:foreground ,nes-coin-gold))))
   `(doom-modeline-lsp-error          ((t (:foreground ,nes-error))))
   `(doom-modeline-lsp-running        ((t (:foreground ,nes-sky-blue))))

   ;; Additional doom-modeline faces
   `(doom-modeline-buffer-major-mode  ((t (:foreground ,nes-mario-red :weight bold))))
   `(doom-modeline-buffer-minor-mode  ((t (:foreground ,nes-fg-faint))))
   `(doom-modeline-persp-name         ((t (:foreground ,nes-sky-blue :weight bold))))
   `(doom-modeline-input-method       ((t (:foreground ,nes-coin-gold :weight bold))))
   `(doom-modeline-panel              ((t (:background ,nes-coin-gold :foreground ,nes-void :weight bold))))
   `(doom-modeline-urgent             ((t (:foreground ,nes-error :weight bold))))
   `(doom-modeline-unread-number      ((t (:foreground ,nes-coin-gold :weight bold))))
   `(doom-modeline-notification       ((t (:foreground ,nes-mario-skin))))
   `(doom-modeline-time               ((t (:foreground ,nes-fg-dim))))
   `(doom-modeline-debug              ((t (:foreground ,nes-mushroom :weight bold))))
   `(doom-modeline-repl-success       ((t (:foreground ,nes-pipe-green))))
   `(doom-modeline-repl-warning       ((t (:foreground ,nes-coin-gold))))
   `(doom-modeline-repl-error         ((t (:foreground ,nes-error))))

   ;; -------------------------------------------------------------------------
   ;; Treemacs — full face coverage
   ;; -------------------------------------------------------------------------

   ;; Core window & text
   `(treemacs-root-face               ((t (:foreground ,nes-coin-gold :weight bold :height 1.1))))
   `(treemacs-directory-face          ((t (:foreground ,nes-sky-blue  :weight bold))))
   `(treemacs-directory-collapsed-face ((t (:foreground ,nes-sky-blue))))
   `(treemacs-file-face               ((t (:foreground ,nes-fg))))
   `(treemacs-symlink-face            ((t (:foreground ,nes-piranha   :slant italic))))
   `(treemacs-executable-file-face    ((t (:foreground ,nes-pipe-green))))

   ;; Selection & focus
   `(treemacs-hl-line-face            ((t (:background ,nes-highlight :extend t))))
   `(treemacs-on-success-pulse-face   ((t (:background ,nes-pipe-dark  :extend t))))
   `(treemacs-on-failure-pulse-face   ((t (:background "#2A0A0A"       :extend t))))

   ;; Tags (imenu-style outline inside files)
   `(treemacs-tags-face               ((t (:foreground ,nes-mario-skin))))
   `(treemacs-term-node-face          ((t (:foreground ,nes-coin-gold  :weight bold))))

   ;; Git integration
   `(treemacs-git-added-face          ((t (:foreground ,nes-pipe-green  :weight bold))))
   `(treemacs-git-modified-face       ((t (:foreground ,nes-coin-gold))))
   `(treemacs-git-renamed-face        ((t (:foreground ,nes-sky-blue    :slant italic))))
   `(treemacs-git-deleted-face        ((t (:foreground ,nes-error       :strike-through t))))
   `(treemacs-git-ignored-face        ((t (:foreground ,nes-fg-faint    :slant italic))))
   `(treemacs-git-conflict-face       ((t (:foreground ,nes-mushroom    :weight bold :underline t))))
   `(treemacs-git-untracked-face      ((t (:foreground ,nes-fg-dim      :slant italic))))
   `(treemacs-git-commit-diff-face    ((t (:foreground ,nes-mario-skin))))

   ;; Async / process indicators
   `(treemacs-async-loading-face      ((t (:foreground ,nes-fg-faint    :slant italic))))

   ;; Fringe indicators (the little arrows/icons in the fringe)
   `(treemacs-fringe-indicator-face   ((t (:foreground ,nes-mario-red))))

   ;; Window number (treemacs uses winum / window-numbering)
   `(treemacs-window-background-face  ((t (:background ,nes-bg-alt))))
   `(treemacs-header-button-face      ((t (:foreground ,nes-coin-gold   :weight bold
                                           :box (:line-width -1 :color ,nes-mario-dark)))))

   ;; Nerd-icons / all-the-icons within treemacs
   ;; These inherit from directory/file faces but we give them explicit colours
   `(treemacs-nerd-icons-root-face    ((t (:foreground ,nes-coin-gold   :weight bold))))
   `(treemacs-nerd-icons-file-face    ((t (:foreground ,nes-fg-dim))))

   ;; Peek / imenu navigation
   `(treemacs-peek-mode-indicator-face ((t (:foreground ,nes-mario-red  :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Doom Emacs — theme system integration
   ;; (these are the faces Doom itself queries when building the modeline,
   ;;  popups, workspaces, etc. — no evil-mode faces needed)
   ;; -------------------------------------------------------------------------

   ;; Doom's own popup / child-frame borders
   `(doom-themes-treemacs-root-face   ((t (:foreground ,nes-coin-gold   :weight bold :height 1.1))))
   `(doom-themes-treemacs-file-face   ((t (:foreground ,nes-fg))))

   ;; Popup frame border (used by lsp-ui, eldoc-box, etc.)
   `(child-frame-border               ((t (:background ,nes-mario-dark))))
   `(internal-border                  ((t (:background ,nes-bg-ui))))

   ;; Workspaces / tab-bar (Doom uses +workspace or tab-bar)
   `(+workspace-tab-selected-face     ((t (:background ,nes-mario-red   :foreground ,nes-coin-gold :weight bold))))
   `(tab-bar                          ((t (:background ,nes-bg-ui       :foreground ,nes-fg-dim))))
   `(tab-bar-tab                      ((t (:background ,nes-mario-red   :foreground ,nes-coin-gold :weight bold
                                           :box (:line-width 2 :color ,nes-mario-red)))))
   `(tab-bar-tab-inactive             ((t (:background ,nes-bg-ui       :foreground ,nes-fg-faint
                                           :box (:line-width 2 :color ,nes-bg-ui)))))
   `(tab-line                         ((t (:background ,nes-bg-ui       :foreground ,nes-fg-dim))))
   `(tab-line-tab                     ((t (:background ,nes-bg-alt      :foreground ,nes-fg))))
   `(tab-line-tab-current             ((t (:background ,nes-mario-red   :foreground ,nes-coin-gold :weight bold))))
   `(tab-line-tab-inactive            ((t (:background ,nes-bg-ui       :foreground ,nes-fg-faint))))
   `(tab-line-highlight               ((t (:background ,nes-highlight))))

   ;; Solaire-mode (Doom uses this to differentiate real buffers from UI)
   ;; Real buffers stay on nes-void; "fake" buffers (sidebars etc.) on bg-alt
   `(solaire-default-face             ((t (:background ,nes-void        :foreground ,nes-fg))))
   `(solaire-fringe-face              ((t (:background ,nes-void))))
   `(solaire-line-number-face         ((t (:background ,nes-void        :foreground ,nes-fg-faint))))
   `(solaire-hl-line-face             ((t (:background ,nes-highlight   :extend t))))
   `(solaire-org-hide-face            ((t (:foreground ,nes-void))))
   `(solaire-mode-line-face           ((t (:background ,nes-mario-red   :foreground ,nes-fg))))
   `(solaire-mode-line-inactive-face  ((t (:background ,nes-bg-ui       :foreground ,nes-fg-faint))))

   ;; Popup / posframe borders (used by vertico-posframe, which-key-posframe…)
   `(which-key-posframe               ((t (:background ,nes-bg-ui))))
   `(which-key-posframe-border        ((t (:background ,nes-mario-dark))))

   ;; Transient (used by Doom's SPC menus)
   `(transient-heading                ((t (:foreground ,nes-mario-red   :weight bold))))
   `(transient-key                    ((t (:foreground ,nes-coin-gold   :weight bold))))
   `(transient-argument               ((t (:foreground ,nes-mario-skin))))
   `(transient-value                  ((t (:foreground ,nes-pipe-green))))
   `(transient-inactive-argument      ((t (:foreground ,nes-fg-faint))))
   `(transient-inactive-value         ((t (:foreground ,nes-fg-faint))))
   `(transient-separator              ((t (:foreground ,nes-fg-faint    :strike-through t))))
   `(transient-enabled-suffix         ((t (:background ,nes-pipe-dark   :foreground ,nes-pipe-green :weight bold))))
   `(transient-disabled-suffix        ((t (:background "#2A0A0A"        :foreground ,nes-fg-faint))))

   ;; Consult (commonly used in Doom for search/navigation)
   `(consult-file                     ((t (:foreground ,nes-fg))))
   `(consult-bookmark                 ((t (:foreground ,nes-coin-gold))))
   `(consult-buffer                   ((t (:foreground ,nes-fg))))
   `(consult-line-number              ((t (:foreground ,nes-fg-faint))))
   `(consult-grep-context             ((t (:foreground ,nes-fg-dim))))
   `(consult-highlight-match          ((t (:background ,nes-pipe-dark   :foreground ,nes-pipe-green :weight bold))))
   `(consult-preview-line             ((t (:background ,nes-highlight   :extend t))))
   `(consult-preview-cursor           ((t (:background ,nes-coin-gold   :foreground ,nes-void))))
   `(consult-narrow-indicator         ((t (:foreground ,nes-mario-skin  :weight bold))))
   `(consult-separator                ((t (:foreground ,nes-fg-faint))))

   ;; Marginalia (annotations in minibuffer completions)
   `(marginalia-documentation         ((t (:foreground ,nes-goomba      :slant italic))))
   `(marginalia-file-priv-dir         ((t (:foreground ,nes-sky-blue    :weight bold))))
   `(marginalia-file-priv-exec        ((t (:foreground ,nes-pipe-green  :weight bold))))
   `(marginalia-file-priv-link        ((t (:foreground ,nes-piranha))))
   `(marginalia-file-priv-other       ((t (:foreground ,nes-fg-dim))))
   `(marginalia-file-priv-rare        ((t (:foreground ,nes-mushroom))))
   `(marginalia-file-priv-read        ((t (:foreground ,nes-coin-gold))))
   `(marginalia-file-priv-write       ((t (:foreground ,nes-mario-skin))))
   `(marginalia-key                   ((t (:foreground ,nes-coin-gold   :weight bold))))
   `(marginalia-lighter               ((t (:foreground ,nes-fg-faint))))
   `(marginalia-mode                  ((t (:foreground ,nes-sky-blue))))
   `(marginalia-modified              ((t (:foreground ,nes-mario-skin  :weight bold))))
   `(marginalia-number                ((t (:foreground ,nes-coin-light))))
   `(marginalia-size                  ((t (:foreground ,nes-coin-gold))))
   `(marginalia-string                ((t (:foreground ,nes-string-tan))))
   `(marginalia-symbol                ((t (:foreground ,nes-mario-skin))))
   `(marginalia-true                  ((t (:foreground ,nes-pipe-green))))
   `(marginalia-type                  ((t (:foreground ,nes-sky-blue))))
   `(marginalia-value                 ((t (:foreground ,nes-fg))))
   `(marginalia-version               ((t (:foreground ,nes-fg-dim))))

   ;; Winum / ace-window (window navigation, common in Doom without evil)
   `(winum-face                       ((t (:foreground ,nes-coin-gold   :weight bold
                                           :background ,nes-mario-red
                                           :box (:line-width -1 :color ,nes-mario-dark)))))
   `(ace-jump-face-foreground         ((t (:foreground ,nes-coin-gold   :weight bold :underline t))))
   `(ace-jump-face-background         ((t (:foreground ,nes-fg-faint))))
   `(aw-leading-char-face             ((t (:foreground ,nes-coin-gold   :weight bold :height 2.0))))
   `(aw-background-face               ((t (:foreground ,nes-fg-faint))))
   `(aw-mode-line-face                ((t (:foreground ,nes-coin-gold   :weight bold))))

   ))

;;; ---------------------------------------------------------------------------
;;; Custom variables (terminal color map)
;;; ---------------------------------------------------------------------------
(custom-theme-set-variables
 'mario-nes
 '(ansi-color-names-vector
   ["#0B0B0B"   ; black   → NES void
    "#D03000"   ; red     → Mario red
    "#00A800"   ; green   → pipe green
    "#F8B800"   ; yellow  → coin gold
    "#0058F8"   ; blue    → water blue
    "#D00040"   ; magenta → mushroom / error
    "#5090D0"   ; cyan    → sky blue
    "#E8DCC8"   ; white   → cloud white
    ]))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'mario-nes)

;;; mario-nes-theme.el ends here
