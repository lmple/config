#!/usr/bin/env bash
# Region screenshot: drag a region, then copy it, save it, or both, in wofi.
# Opened by Print and Super+Shift+S (hyprland.lua).
set -euo pipefail

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"

region="$(slurp)" || exit 0 # Esc: no region

# Capture before the menu opens, so wofi isn't in the shot
shot="$(mktemp --suffix=.png)"
trap 'rm -f "$shot"' EXIT
grim -g "$region" "$shot"

choice="$(printf '%s\n' Copy Save 'Copy and save' |
  wofi --dmenu --insensitive --prompt Screenshot --lines 4)" || exit 0 # Esc: discard

copy() { wl-copy --type image/png <"$shot"; }

save() {
  mkdir -p "$dir"
  local file
  file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
  cp "$shot" "$file"
  # The file is already saved, so a missing notification daemon isn't an error
  notify-send --app-name=screenshot "Screenshot saved" "$file" || true
}

case "$choice" in
  Copy) copy ;;
  Save) save ;;
  'Copy and save') copy && save ;;
  *) exit 0 ;;
esac
