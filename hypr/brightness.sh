#!/usr/bin/env bash
# Screen brightness up or down by 5%, never below 5%: the same steps and floor
# as scrolling on Waybar's brightness pill, so keys and pill agree.
# Bound to the XF86MonBrightness keys (hyprland.lua). Usage: brightness.sh up|down
set -euo pipefail

direction="${1:?usage: brightness.sh up|down}"

# The first backlight, as Waybar picks when no device is set; none on a desktop
device="$(find /sys/class/backlight -mindepth 1 -maxdepth 1 -printf '%f\n' | sort | head -n 1)"
[[ -n "$device" ]] || exit 0

current="$(<"/sys/class/backlight/$device/brightness")"
max="$(<"/sys/class/backlight/$device/max_brightness")"
step=$(((max * 5 + 99) / 100))
floor=$step

case "$direction" in
  up) target=$((current + step)) ;;
  down) target=$((current - step)) ;;
  *) echo "usage: brightness.sh up|down" >&2; exit 2 ;;
esac

target=$((target > max ? max : target))
target=$((target < floor ? floor : target))

# Through logind, which lets the session's user write the backlight without root
busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto \
  org.freedesktop.login1.Session SetBrightness ssu backlight "$device" "$target"
