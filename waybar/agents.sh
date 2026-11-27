#!/usr/bin/env bash
# Waybar's custom/agents module (waybar/config.jsonc): the coding agents
# running in zellij panes, and which of them wait for you. Only to look at:
# the list is in the tooltip, and a click does nothing.
#
# Why zellij: every agent here runs in a zellij pane (cockpits, Emacs's
# emacs-* sessions, pi-local in main), and zellij 0.46 tracks each pane's state
# (`list-panes --json` .attention), which Claude Code sets itself: Working
# while it runs, NeedsYou when it asks. So no agent needs a hook for this.
# pi sets nothing, so it only ever shows as running.
#
#   agents.sh          print the module's JSON line (Waybar runs it every few s)
#   agents.sh --json   print the agents as one JSON array (Emacs's C-c o a)
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
        | {session: $session, id: .id, pane: .title, cmd: $cmd,
           text: ($a.text // ""),
           state: (if $a.muted == true then "running"
                   elif $a.status == "NeedsYou"
                        or ($a.status // "" | test("^(Waiting|Needs)"))
                        or ($a.status == "Done" and $a.seen != true) then "waiting"
                   elif $a.status == "Working" then "working"
                   else "running" end)}' "${AGENTS[@]}" ||
      true
  done < <(sessions)
}

# The agents as one JSON array, waiting first, then working: the tooltip's
# order
ordered_agents() {
  agent_panes | jq -sc 'sort_by({waiting: 0, working: 1, running: 2}[.state], .session, .pane)'
}

# Waybar's JSON: counts in the bar, one line per agent in the tooltip. Empty
# text hides the module when nothing runs.
module() {
  ordered_agents | jq -c '
    def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
    def count(s): map(select(.state == s)) | length;
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
       tooltip: (map("\(.session) › \(.pane)   \(.cmd)   \(.state)"
                       # What it does, or what it asks you
                       + (if .state != "running" and .text != ""
                          then "\n    \(.text[0:80])" else "" end)
                       | esc)
                 | join("\n"))}'
}

case "${1:-}" in
  "") module ;;
  --json) ordered_agents ;;
  *)
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
