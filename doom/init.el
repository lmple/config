;;; init.el -*- lexical-binding: t; -*-

(doom!
 :completion
 (corfu +orderless)
 vertico

 :ui
 doom
 (emoji +unicode)
 hl-todo
 indent-guides
 ligatures
 minimap
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
 (csharp +lsp)
 data
 emacs-lisp
 (fsharp +lsp)
 (gdscript +lsp)
 json
 (javascript +tree-sitter)
 latex
 lua
 markdown
 (ocaml +lsp)
 org
 plantuml
 graphviz
 (python +lsp)
 (rust +lsp)
 (scheme +guile)
 sh
 web
 yaml

 :app
 calendar
 emms
 irc
 )
