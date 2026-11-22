#!/usr/bin/env bash
# Power menu: pick lock, suspend, logout, reboot or shutdown in wofi.
# Opened by Super+Escape (hyprland.lua) and Waybar's power button.
set -euo pipefail

choice="$(printf '%s\n' Lock Suspend Logout Reboot Shutdown |
  wofi --dmenu --insensitive --prompt Power --lines 6)" || exit 0 # Esc: no choice

case "$choice" in
  # Through logind, so hypridle's lock_cmd starts the one hyprlock
  Lock) loginctl lock-session ;;
  # hypridle's before_sleep_cmd locks first
  Suspend) systemctl suspend ;;
  # 0.57 dispatches take Lua
  Logout) hyprctl dispatch 'hl.dsp.exit()' ;;
  Reboot) systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
  *) exit 0 ;;
esac
