#!/bin/sh
# Starts llama.cpp's server for systemd/llama-server@.service, whichever way
# `deps.sh --llama` installed it; the arguments are llama-server flags.

# Arch (llama.cpp-cuda from the AUR). Absolute path on purpose: an old
# hand-built /usr/local/bin copy would otherwise win (see deps.sh --llama).
if [ -x /usr/bin/llama-server ]; then
  exec /usr/bin/llama-server "$@"
fi

# Elsewhere, llama.app's installer ships one `llama` binary whose `serve`
# subcommand is llama-server.
exec "$HOME/.local/bin/llama" serve "$@"
