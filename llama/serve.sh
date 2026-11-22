#!/bin/sh
# Starts llama.cpp's server for systemd/llama-server@.service; the arguments
# are llama-server flags. `deps.sh --llama` installs llama.app's single
# `llama` binary on every machine, whose `serve` subcommand is llama-server.
# Only that one: a distro package's llama-server can break on an upgrade of
# a library it shares (Arch's did, with ggml 1.0).
exec "$HOME/.local/bin/llama" serve "$@"
