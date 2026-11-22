#!/usr/bin/env bash
# Open a file in the tab's Helix pane, the one named "editor" (as in
# zellij/layouts/cockpit.kdl), from any other pane, then focus that pane. A tab
# without one, such as a plain session's, gets a new Helix pane by that name.
#
# Why this exists: Helix has no server to send a file to, as emacsclient does
# for Emacs, so this types the :open command into the editor pane instead.
#
#   hx-open.sh FILE[:LINE]   open FILE, at LINE if given (for the agent or shell)
#   hx-open.sh --pick        pick a file under the current directory with fzf
#                            first; Alt e in config.kdl runs this in a floating pane
set -euo pipefail

# Set by --pick: its floating pane closes on exit, which would hide the error
picking=false

die() {
  printf 'hx-open: %s\n' "$*" >&2
  if "$picking"; then
    printf 'Press any key.' >&2
    read -rsn1 || true
  fi
  exit 1
}

# The nearest directory above $1 with a .git, as zshrc's cockpit finds a
# project (without running git), else $1 itself
project_root() {
  local dir=$1
  until [[ -e "$dir/.git" || "$dir" == / ]]; do dir=${dir%/*}; dir=${dir:-/}; done
  if [[ -e "$dir/.git" ]]; then printf '%s\n' "$dir"; else printf '%s\n' "$1"; fi
}

# A new Helix pane named "editor", so the next call types into it instead.
# It starts in the file's project: Helix takes its workspace (trust, language
# servers) from its directory. Through an interactive zsh, as in the cockpit
# layout: zshrc sets HELIX_STEEL_CONFIG and HELIX_RUNTIME, which a session
# started before them lacks, and quitting Helix leaves a shell.
new_editor_pane() {
  local file=$1 line=$2 pane
  # $1 is for the inner zsh, which gets the file as an argument, never as code
  # shellcheck disable=SC2016
  pane="$(zellij run --name editor --cwd "$(project_root "${file%/*}")" -- \
    zsh -ic 'hx "$1"; exec zsh' zsh "$file${line:+:$line}")"
  # Run from the Alt e floating pane, focus would go back to the tiled pane
  # under it; zellij run prints the new pane's id
  zellij action focus-pane-id "$pane"
}

# The pane the layout names "editor", in the tab of the pane this runs in (the
# Alt e floating pane belongs to its tab too). Found from $ZELLIJ_PANE_ID, not
# current-tab-info, which is the tab a client looks at: another tab, or none.
editor_pane() {
  zellij action list-panes --all --json | jq -r --argjson me "$ZELLIJ_PANE_ID" '
    first(.[] | select(.is_plugin == false and .id == $me) | .tab_id) as $tab
    | first(.[] | select(.is_plugin == false and .tab_id == $tab
                         and .title == "editor")
                | "terminal_\(.id)") // empty'
}

open_in_editor() {
  local spec=$1 file=$1 line=""
  # FILE:LINE, unless a file is really named that way
  if [[ ! -e "$spec" && "$spec" =~ ^(.+):([0-9]+)$ ]]; then
    file=${BASH_REMATCH[1]}
    line=${BASH_REMATCH[2]}
  fi
  [[ -f "$file" ]] || die "no such file: $file"
  # Absolute, since the editor pane's directory is the project root, not ours
  file="$(realpath -- "$file")"
  # Single quotes are literal in Helix's command line (no % expansion), and
  # have no escape for a quote inside them
  [[ "$file" != *"'"* ]] || die "can't pass a path containing ' to Helix: $file"

  local pane
  [[ -n "${ZELLIJ:-}" && "${ZELLIJ_PANE_ID:-}" =~ ^[0-9]+$ ]] || die "not inside a zellij pane"
  # Checked here: a failure inside $(...) doesn't stop the script under set -e
  pane="$(editor_pane)" || die "can't list this session's panes"
  if [[ -z "$pane" ]]; then
    new_editor_pane "$file" "$line" || die "can't open a Helix pane"
    return
  fi

  # Esc first: in insert mode or a picker the command would be typed as text.
  # The pause keeps Helix from reading Esc and ':' together as Alt-:.
  zellij action write --pane-id "$pane" 27
  sleep 0.05
  zellij action write-chars --pane-id "$pane" ":open '$file'"$'\r'
  if [[ -n "$line" ]]; then
    zellij action write-chars --pane-id "$pane" ":goto $line"$'\r'
  fi
  zellij action focus-pane-id "$pane"
}

pick() {
  local file
  file="$(fd --type f --hidden --exclude .git | fzf --layout=reverse --prompt='Open in Helix> ')" ||
    exit 0
  open_in_editor "$file"
}

main() {
  case "${1:-}" in
    --pick)
      picking=true
      pick
      ;;
    "" | -h | --help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) open_in_editor "$1" ;;
  esac
}

main "$@"
