;;; init.scm -*- scheme -*-
;; Run by Helix's Steel build (deps.sh --helix) right after helix.scm.

;; Reload a buffer when its file changes on disk, e.g. when the agent in the
;; cockpit's other pane edits it: Helix only rereads a file on :reload.
;; It skips files no newer than Helix's own last save, and waits 2 s so a save
;; from Helix itself is done first. A buffer with unsaved edits is reloaded
;; too, but as one step of its undo history, so `u' brings the edits back.
(require "helix-file-watcher/file-watcher.scm")
(spawn-watcher)
