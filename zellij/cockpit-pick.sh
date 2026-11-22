#!/usr/bin/env bash
# Go to a project's cockpit (zellij/layouts/cockpit.kdl) from any pane, the
# project picked with fzf: live cockpits first (marked ●), then every git
# repo under ROOTS. A path typed in the prompt that matches nothing is opened
# as is. Alt c in config.kdl runs this in a floating pane.
#
# Why through zshrc's `cockpit`: it names, creates and records the session,
# and refuses a name another project already holds; this only picks.
#
#   cockpit-pick.sh          pick with fzf, then go to that cockpit
#   cockpit-pick.sh DIR      go to DIR's cockpit without picking
#   cockpit-pick.sh --list   print the choices
set -euo pipefail

# Where repos are looked for, three levels down
readonly ROOTS=("$HOME/sources")
# Where `cockpit` records each live cockpit's root (my_cockpit_session)
readonly RECORDS="${XDG_RUNTIME_DIR:-/tmp/cockpit-$UID}/cockpit-roots"
readonly LIVE_MARK="● "
readonly REPO_MARK="  "

# The float closes on exit, which would hide the error: wait for a key first
die() {
  printf 'cockpit-pick: %s\n' "$*" >&2
  printf 'Press any key.' >&2
  read -rsn1 || true
  exit 1
}

# ~ for $HOME, shorter to read in the list
tilde() { sed "s#^$HOME\(/\|$\)#~\1#"; }

# Roots of the live cockpits. A record outlives its session until a reboot
# clears the runtime dir, so only those whose session is live count.
live_roots() {
  local live session record
  live="$(zellij list-sessions --no-formatting 2>/dev/null | awk '!/EXITED/ { print $1 }')"
  [[ -d "$RECORDS" ]] || return 0
  for record in "$RECORDS"/cockpit-*; do
    [[ -r "$record" ]] || continue
    session="${record##*/}"
    grep -qxF -- "$session" <<<"$live" && cat -- "$record"
  done
  return 0
}

# Git repos under ROOTS; a .git file is a worktree's
repos() {
  local root existing=()
  for root in "${ROOTS[@]}"; do [[ -d "$root" ]] && existing+=("$root"); done
  ((${#existing[@]})) || return 0
  fd --hidden --no-ignore --max-depth 3 --type d --type f '^\.git$' "${existing[@]}" |
    sed 's|/\.git/\{0,1\}$||' | sort -u
}

# The choices, live cockpits first, each directory once
choices() {
  local live
  live="$(live_roots | sort -u)"
  [[ -z "$live" ]] || tilde <<<"$live" | sed "s|^|$LIVE_MARK|"
  repos | grep -vxF -- "${live:-/nonexistent}" | tilde | sed "s|^|$REPO_MARK|" || true
}

open() {
  local dir=$1
  # A literal ~, as the list shows it or as typed in the prompt
  # shellcheck disable=SC2088
  [[ "$dir" == "~" || "$dir" == "~/"* ]] && dir="$HOME${dir#\~}"
  [[ -d "$dir" ]] || die "not a directory: $dir"
  [[ -n "${ZELLIJ:-}" ]] || die "not inside zellij"
  # The path is an argument of the inner zsh, never code. An interactive zsh
  # reads zshrc, which defines `cockpit`; inside zellij it starts no session.
  # shellcheck disable=SC2016
  zsh -ic 'cockpit "$1"' zsh "$dir" || die "no cockpit for $dir"
}

pick() {
  local out rc=0 query choice
  out="$(choices | fzf --layout=reverse --prompt='Cockpit> ' --print-query)" || rc=$?
  # 1: nothing matched, so the query is the path; 130: Esc
  case "$rc" in 0 | 1) ;; *) exit 0 ;; esac
  query="$(sed -n 1p <<<"$out")"
  choice="$(sed -n 2p <<<"$out")"
  if [[ -n "$choice" ]]; then
    choice="${choice#"$LIVE_MARK"}"
    open "${choice#"$REPO_MARK"}"
  elif [[ -n "$query" ]]; then
    open "$query"
  fi
}

case "${1:-}" in
  "") pick ;;
  --list) choices ;;
  -h | --help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) open "$1" ;;
esac
