;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

(package! shell-maker)
(package! acp)
(package! agent-shell)

(package! tlc2langgraph
  :recipe (:host github
           :repo "lmple/tlc2langgraph.el"
           :files ("*.el" "tlc2langgraph/*.el")))

(package! minuet :recipe (:host github :repo "milanglacier/minuet-ai.el"))
