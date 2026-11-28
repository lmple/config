#!/usr/bin/env bash
# Symlink the configs into ~ and ~/.config. Safe to re-run, from any directory.
set -euo pipefail

# The repo is where this script lives, not the caller's directory: with
# $(pwd), running it from elsewhere linked to files that don't exist.
REPO_DIR="$(dirname "$(realpath "$0")")"
readonly REPO_DIR

# Point DEST at SRC (relative to the repo). An existing symlink is replaced,
# so a re-run is a no-op; a real file or directory stops the script instead,
# since `ln -sfn` would put the link inside a directory or a plain `ln -s`
# would fail halfway.
link() {
  local src="$REPO_DIR/$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    printf 'error: %s exists and is not a symlink; move it away and re-run\n' "$dest" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  printf '%s -> %s\n' "$dest" "$src"
}

link zshrc "$HOME/.zshrc"
link starship.toml "$HOME/.config/starship.toml"
link zellij "$HOME/.config/zellij"
link alacritty "$HOME/.config/alacritty"
link doom "$HOME/.config/doom"
# Hyprland session (picked at the login screen; Plasma stays the fallback)
link hypr "$HOME/.config/hypr"
link waybar "$HOME/.config/waybar"
link mako "$HOME/.config/mako"

# llama-server presets and its user service (enable it per machine, see README)
link llama "$HOME/.config/llama"
link systemd/llama-server@.service "$HOME/.config/systemd/user/llama-server@.service"
# pi on that server: its launcher and guard, and the provider in pi's own
# directory, linked as a file since ~/.pi/agent also holds pi's logins
link pi "$HOME/.config/pi"
link pi/models.json "$HOME/.pi/agent/models.json"
