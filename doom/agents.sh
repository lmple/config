#!/usr/bin/env bash
# The coding agents running in zellij panes, and which of them wait for you,
# for Emacs's agents list (doom/lisp/agents.el, C-c o a). Emacs's own Claude
# runs outside zellij: the list reads that one from Emacs itself.
#
# Why zellij: every other agent here runs in a zellij pane (Emacs's
# emacs-* sessions, pi-local in main), and zellij 0.46 tracks each pane's state
# (`list-panes --json` .attention), which Claude Code sets itself: Working
# while it runs, NeedsYou when it asks. So no agent needs a hook for this.
# pi sets nothing, so it only ever shows as running.
#
#   agents.sh   print the agents as one JSON array, waiting first
set -euo pipefail

# Basenames of the commands that count as agents
readonly AGENTS=(claude pi opencode)

# Live sessions, one name per line: an EXITED one (lost to a reboot) has no
# panes to ask about
sessions() {
  zellij list-sessions --no-formatting 2>/dev/null | awk '!/EXITED/ { print $1 }'
}

# Every agent pane of every live session, one JSON object per line. A session
# that quits between the two calls is skipped rather than failing the list.
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

# The agents as one JSON array, waiting first, then working
ordered_agents() {
  agent_panes | jq -sc 'sort_by({waiting: 0, working: 1, running: 2}[.state], .session, .pane)'
}

case "${1:-}" in
  "") ordered_agents ;;
  *)
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
