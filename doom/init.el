;;; init.el -*- lexical-binding: t; -*-

(doom!
 :completion
 company
 vertico

 :config
 (default +bindings +smartparens)

 :ui
 doom
 (emoji +unicode)
 hl-todo
 indent-guides
 ligatures
 modeline
 nav-flash
 ophints
 (popup +defaults)
 smooth-scroll
 tabs
 treemacs
 unicode
 (vc-gutter +pretty)
 vi-tilde-fringe
 window-select
 workspaces

 :editor
 file-templates
 fold
 (format +onsave)
 snippets
 (whitespace +guess +trim)

 :emacs
 dired
 electric
 eww
 ibuffer
 tramp
 undo
 vc

 :term
 eshell
 vterm

 :checkers
 syntax
 (spell +flyspell)
 grammar

 :tools
 biblio
 debugger
 direnv
 ein
 (eval +overlay)
 lookup
 llm
 (lsp +eglot)
 magit
 make
 pass
 pdf
 tmux
 tree-sitter
 upload

 :os
 (:if (featurep :system 'macos) macos)
 tty

 :lang
 (cc +lsp)
 coq
 data
 emacs-lisp
 (gdscript +lsp)
 (haskell +lsp)
 json
 (javascript +lsp)
 latex
 markdown
 (ocaml +lsp)
 (org +brain + dragndrop +gnuplot +journal +jupyter +noter +pandoc +present +pretty +roam2)
 plantuml
 graphviz
 (python +lsp +pyright +pyenv)
 (rust +lsp)
 sh
 web
 yaml

 :app
 calendar
 emms
 )
