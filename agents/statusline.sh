#!/usr/bin/env bash
# Claude Code status line: model, effort, context used, directory and branch.
# The context share is the point: it says when to /clear before a long
# session gets slow and loses track.
set -euo pipefail

payload=$(cat)

# A fresh session has no context measurement until the first reply, so a
# null used_percentage shows as "–"; model and directory are always sent.
# Fields are split on the unit separator, not a tab: read collapses runs of
# whitespace separators, so an empty effort would shift the fields after it.
IFS=$'\x1f' read -r model effort used dir < <(
  jq -r '[
    .model.display_name // "",
    .effort.level // "",
    (.context_window.used_percentage | if . == null then "–" else "\(.)%" end),
    .workspace.current_dir // ""
  ] | join("\u001f")' <<<"$payload"
)

if [[ -z "$model" || -z "$dir" ]]; then
  # Shown in the status line itself, so a changed payload is noticed at once.
  printf 'status line: payload has no model or directory, fix ~/.claude/statusline.sh\n'
  exit 0
fi

location=$(basename "$dir")
if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current)
  # Detached HEAD has no branch name; the commit is the useful part then.
  [[ -n "$branch" ]] || branch=$(git -C "$dir" rev-parse --short HEAD)
  location="$location ($branch)"
fi

printf '%s%s · ctx %s · %s\n' "$model" "${effort:+ ($effort)}" "$used" "$location"
