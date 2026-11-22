#!/usr/bin/env bash
# Low-battery alerts while discharging: one at LOW%, then an urgent one that
# stays until clicked at CRITICAL%. Started by hyprland.lua; mako/config's
# [app-name=battery] draws them above fullscreen windows.
set -euo pipefail

# Overridable so the script can be tried against a fake battery directory
readonly BATTERY="${BATTERY:-/sys/class/power_supply/BAT0}"
readonly LOW="${LOW:-15}" # where Waybar turns the battery red
readonly CRITICAL="${CRITICAL:-5}"
readonly INTERVAL="${INTERVAL:-60}"

level=none # the highest alert already sent during this discharge
id=0       # the alert on screen: the critical one replaces the low one

# Send or replace the alert and print its id. It fails while mako isn't up
# yet (right after login); the caller then keeps its level, so the next poll
# retries instead of the alert being lost.
alert() {
  notify-send --app-name=battery --print-id --replace-id="$id" "$@"
}

while true; do
  capacity="$(<"$BATTERY/capacity")"
  status="$(<"$BATTERY/status")"
  if [[ "$status" != Discharging ]]; then
    # Plugged in: drop the alert left on screen, and alert again next discharge
    if [[ "$level" != none ]]; then
      makoctl dismiss -n "$id" 2>/dev/null || true # it may have expired already
      level=none
    fi
  elif ((capacity <= CRITICAL)) && [[ "$level" != critical ]]; then
    if new_id="$(alert --urgency=critical "Battery critical: ${capacity}%" "Plug in now")"; then
      id="$new_id" level=critical
    fi
  elif ((capacity <= LOW)) && [[ "$level" == none ]]; then
    if new_id="$(alert "Battery low: ${capacity}%" "Plug in soon")"; then
      id="$new_id" level=low
    fi
  fi
  sleep "$INTERVAL"
done
