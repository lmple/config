#!/usr/bin/env bash
# Pick a URL from the focused Zellij pane and open or copy it.
#
# Why this exists: Zellij links URLs one screen row at a time, so a URL that
# wraps opens truncated when clicked (zellij-org/zellij#3436), and the outer
# terminal only sees the rows Zellij draws. `dump-screen` joins soft-wrapped
# rows back into logical lines, so URLs read from it are whole.
#
# Bound to Alt u in config.kdl, which runs it in a floating pane.
#   url-picker.sh                  pick with fzf: Enter opens, Ctrl-y copies
#   url-picker.sh --list [PANE]    print the URLs, newest first (for testing)
set -euo pipefail

# The picker runs in its own floating pane, which is now the focused one. Zellij
# tracks focus per layer, so the pane we were called from is still marked
# focused among the tiled panes of the active tab.
target_pane() {
  local tab
  tab="$(zellij action current-tab-info | awk '$1 == "id:" { print $2 }')"
  zellij action list-panes --all --json | jq -r --argjson tab "$tab" '
    first(.[] | select(.is_plugin == false and .is_floating == false
                       and .is_focused and .tab_id == $tab)
              | "terminal_\(.id)") // empty'
}

# ASCII URL characters only, so TUI box-drawing borders never end up in a URL;
# the last character excludes punctuation that usually ends a sentence. A
# closing paren is kept only if it closes one inside the URL, so
# "(see https://x/y)" drops it but "https://x/Foo_(bar)" keeps it.
extract_urls() {
  LC_ALL=C grep -oE "https?://[A-Za-z0-9._~:/?#@!\$&()*+,;=%-]*[A-Za-z0-9_~/#@\$&()*+=%-]" |
    tac | awk '{
      while ($0 ~ /[)]$/ && gsub(/[(]/, "(") < gsub(/[)]/, ")")) $0 = substr($0, 1, length($0) - 1)
      if (!seen[$0]++) print
    }'
}

urls_of() {
  zellij action dump-screen --full --pane-id "$1" | extract_urls || true
}

# setsid: the floating pane closes as soon as this script exits, which would
# otherwise take the browser launcher or the clipboard owner down with it.
open_url() { setsid -f xdg-open "$1" >/dev/null 2>&1; }

copy_url() {
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    setsid -f wl-copy -- "$1" >/dev/null 2>&1
  else
    printf '%s' "$1" | setsid -f xclip -selection clipboard >/dev/null 2>&1
  fi
}

wait_key() {
  printf '%s Press any key.' "$1"
  read -rsn1 || true
}

main() {
  local pane=""
  if [[ "${1:-}" == --list ]]; then
    pane="${2:-$(target_pane)}"
    [[ -n "$pane" ]] || { echo "no focused tiled pane found" >&2; exit 1; }
    urls_of "$pane"
    return
  fi

  pane="$(target_pane)"
  [[ -n "$pane" ]] || { wait_key "No focused tiled pane found."; exit 1; }
  local urls
  urls="$(urls_of "$pane")"
  [[ -n "$urls" ]] || { wait_key "No URLs in this pane."; exit 0; }

  # --expect prints the key that ended fzf on the first line, the choice on the second
  local out key url
  out="$(fzf --layout=reverse --prompt='URL> ' --expect=ctrl-y \
    --header='Enter: open  ·  Ctrl-y: copy' <<<"$urls")" || exit 0
  key="$(sed -n 1p <<<"$out")"
  url="$(sed -n 2p <<<"$out")"
  [[ -n "$url" ]] || exit 0
  if [[ "$key" == ctrl-y ]]; then copy_url "$url"; else open_url "$url"; fi
}

main "$@"
