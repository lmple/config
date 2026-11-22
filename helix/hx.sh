#!/bin/sh
# hx: the Steel build of Helix (deps.sh --helix installs it as hx-steel),
# always with HELIX_STEEL_CONFIG set.
#
# Why: without it, that build runs a workspace's .helix/helix.scm and init.scm
# instead of ours whenever both exist, with no workspace trust check, so any
# repo could run Scheme, and so shell commands, when Helix opens it. zshrc sets
# it too, but a shell started before zshrc did (an old zellij pane) lacks it;
# deps.sh links ~/.cargo/bin/hx here, so every shell that finds Helix gets this.
HELIX_STEEL_CONFIG="$HOME/.config/helix"
export HELIX_STEEL_CONFIG
exec "$HOME/.cargo/bin/hx-steel" "$@"
