#!/usr/bin/env bash
# pi on the local llama-server (systemd/llama-server@.service), with the tool
# rules gptel has in Emacs (pi/guard.ts). Run by the pi pane of the main
# zellij session (zellij/layouts/main.kdl), by the cockpit's floating pi
# (zellij/layouts/cockpit.kdl) and by zshrc's `pi-local`; arguments go to pi.
#
# pi's built-in llama.cpp provider counts as set up once LLAMA_BASE_URL is
# set; its key comes from pi/models.json (linked into ~/.pi/agent by
# install.sh), which reads the key file, so the key is never in the
# environment. A `/login llama.cpp` in pi would store a key that wins over
# the file, so don't. This also picks the model, as gptel does
# (my/gptel-llama-server-models in doom/lisp/llm.el): a preset, the loaded one
# first, since the router also lists every GGUF in the Hugging Face cache
# without the presets' flags.
set -euo pipefail

readonly HOST=127.0.0.1:9091 # systemd/llama-server@.service
readonly KEY_FILE="$HOME/.config/llama-server/api-key"
readonly WAIT_SECONDS=60
HERE="$(dirname "$(realpath "$0")")"
readonly HERE

die() {
  printf 'pi-local: %s\n' "$*" >&2
  exit 1
}

[[ -r "$KEY_FILE" ]] || die "no llama-server API key in $KEY_FILE (see README)"

# The key goes to curl as a header file, so it never shows in a process's
# arguments, which any local user can list
models() {
  curl -fsS --max-time 2 \
    -H @<(printf 'Authorization: Bearer %s\n' "$(<"$KEY_FILE")") \
    "http://$HOST/v1/models"
}

# At login the main session starts with the desktop, and the service may
# not be listening yet
json=""
for ((waited = 0; waited < WAIT_SECONDS; waited += 2)); do
  if json="$(models 2>/dev/null)"; then
    break
  fi
  json=""
  ((waited > 0)) || printf 'Waiting for llama-server at %s...\n' "$HOST" >&2
  sleep 2
done
[[ -n "$json" ]] ||
  die "llama-server isn't reachable at $HOST; see: systemctl --user status 'llama-server@*'"

# A server started on a single model has no "source": count it as a preset
model="$(jq -r '
  [.data[] | select((.source // "preset") == "preset")]
  | (map(select((.status // {}).value == "loaded")) + .)
  | .[0].id // empty' <<<"$json")"
[[ -n "$model" ]] || die "llama-server at $HOST has no preset model"

# The notes it is meant to answer from (MY_NOTES_DIR per machine, in
# ~/.extra_config). Named in the prompt because the cockpit's float starts in
# ~, where the guard refuses a grep of "." (it holds ~/.ssh): the model has
# to know where to search instead. Left out when the folder doesn't exist, so
# the model isn't sent looking for it.
notes="${MY_NOTES_DIR:-$HOME/notes}"
hint=()
if [[ -d "$notes" ]]; then
  hint=(--append-system-prompt "The user's Markdown notes and documentation \
are in $notes. Look there first for documentation questions. Search inside \
$notes, or inside a project's directory, never the home directory as a \
whole: that search is refused, because it holds credentials.")
fi

# Never another provider: this pane is for the local model only. bash isn't
# among the tools, and the guard refuses any tool not listed here anyway.
export LLAMA_BASE_URL="http://$HOST"
exec pi --provider llama.cpp --model "$model" \
  --tools read,grep,find,ls,edit,write \
  --extension "$HERE/guard.ts" "${hint[@]}" "$@"
