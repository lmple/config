#!/usr/bin/env bash
# Waybar's custom/agents module (waybar/config.jsonc): the coding agents
# running in zellij panes, and which of them wait for you.
#
# Why zellij: every agent here runs in a zellij pane (cockpits, Emacs's
# emacs-* sessions, main's pi), and zellij 0.46 tracks each pane's state
# (`list-panes --json` .attention), which Claude Code sets itself: Working
# while it runs, NeedsYou when it asks. So no agent needs a hook for this.
# pi sets nothing, so it only ever shows as running.
#
#   agents.sh          print the module's JSON line (Waybar runs it every few s)
#   agents.sh --jump   on click: move a terminal to the next pane that needs
#                      you and raise its window
set -euo pipefail

# Basenames of the commands that count as agents
readonly AGENTS=(claude pi opencode)

# Live sessions, one name per line: an EXITED one (lost to a reboot) has no
# panes to ask about
sessions() {
  zellij list-sessions --no-formatting 2>/dev/null | awk '!/EXITED/ { print $1 }'
}

# Every agent pane of every live session, one JSON object per line. A session
# that quits between the two calls is skipped rather than failing the module.
agent_panes() {
  local s
  while read -r s; do
    zellij -s "$s" action list-panes --all --json 2>/dev/null |
      jq -c --arg session "$s" --args '
        ($ARGS.positional) as $agents
        | .[]
        | select(.is_plugin == false and .exited != true)
        | ((.pane_command // "") | split(" ")[0] | split("/")[-1]) as $cmd
        | select($agents | index($cmd))
        | (.attention // {}) as $a
        | {session: $session, pane: .title, cmd: $cmd, text: ($a.text // ""),
           state: (if $a.muted == true then "running"
                   elif $a.status == "NeedsYou"
                        or ($a.status // "" | test("^(Waiting|Needs)"))
                        or ($a.status == "Done" and $a.seen != true) then "waiting"
                   elif $a.status == "Working" then "working"
                   else "running" end)}' "${AGENTS[@]}" ||
      true
  done < <(sessions)
}

# Waybar's JSON: counts in the bar, one line per agent in the tooltip. Empty
# text hides the module when nothing runs.
module() {
  agent_panes | jq -sc '
    def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
    def count(s): map(select(.state == s)) | length;
    def rank: {waiting: 0, working: 1, running: 2}[.state];
    (count("waiting")) as $waiting
    | (count("working")) as $working
    | ([if $working > 0 then " \($working)" else empty end,
        if $waiting > 0 then "<span color=\"#b14242\"> \($waiting)</span>"
        else empty end]) as $parts
    | {text: (if length == 0 then ""
              elif ($parts | length) > 0 then $parts | join("  ")
              else " \(length)" end),
       class: (if $waiting > 0 then "waiting"
               elif $working > 0 then "working" else "running" end),
       tooltip: (sort_by(rank, .session, .pane)
                 | map("\(.session) › \(.pane)   \(.cmd)   \(.state)"
                       # What it does, or what it asks you
                       + (if .state != "running" and .text != ""
                          then "\n    \(.text[0:80])" else "" end)
                       | esc)
                 | join("\n"))}'
}

# Client id -> session, one "id session" per line
clients() {
  local s
  while read -r s; do
    zellij -s "$s" action list-clients 2>/dev/null |
      awk -v s="$s" 'NR > 1 && $1 ~ /^[0-9]+$/ { print $1, s }'
  done < <(sessions)
}

# go-to-next-attention needs a session with a client to move: run from
# Waybar, outside zellij, it moves that session's client to the pane. The
# window is then found by its title, which zellij sets to "session | pane".
jump() {
  local before first session moved re lua
  before="$(clients)"
  [[ -n "$before" ]] || exit 0 # no terminal attached anywhere
  first="${before%%$'\n'*}"
  session="${first#* }"
  zellij -s "$session" action go-to-next-attention 2>/dev/null || exit 0
  sleep 0.3
  # A client that changes session gets a new id there, so the moved one is
  # the line that wasn't there before; none means it stayed in $session
  moved="$(clients | awk 'NR == FNR { seen[$0]; next } !($0 in seen) { print $2; exit }' \
    <(printf '%s\n' "$before") -)"
  session="${moved:-$session}"
  # A regex matched against the whole title, so a session named by hand with
  # . or + in it is escaped; then a Lua string, since Hyprland's Lua config
  # makes `hyprctl dispatch` take a dispatcher call
  re="$(sed 's/[][\.*^$+?(){}|/]/\\&/g' <<<"$session") \\| .*"
  lua="${re//\\/\\\\}"
  lua="${lua//\"/\\\"}"
  hyprctl dispatch "hl.dsp.focus({ window = \"title:$lua\" })" >/dev/null
}

case "${1:-}" in
  "") module ;;
  --jump) jump ;;
  *)
    sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
