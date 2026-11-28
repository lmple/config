#!/usr/bin/env bash
# Claude Code status line: model, effort, context used, plan usage, directory
# and branch. The context share says when to /clear before a long session gets
# slow and loses track; the plan usage, how much of the 5-hour and weekly
# limits is gone and when the 5-hour one frees up.
set -euo pipefail

payload=$(cat)

# A fresh session has no context measurement until the first reply, so a
# null used_percentage shows as "–"; model and directory are always sent.
# rate_limits comes only for Pro/Max/Ultra plans and after the first reply,
# and each window drops out once it resets, so a missing one is "".
# Fields are split on the unit separator, not a tab: read collapses runs of
# whitespace separators, so an empty effort would shift the fields after it.
IFS=$'\x1f' read -r model effort used dir five_pct five_reset week_pct < <(
  jq -r '[
    .model.display_name // "",
    .effort.level // "",
    (.context_window.used_percentage | if . == null then "–" else "\(.)%" end),
    .workspace.current_dir // "",
    (.rate_limits.five_hour.used_percentage | if . == null then "" else round end),
    .rate_limits.five_hour.resets_at // "",
    (.rate_limits.seven_day.used_percentage | if . == null then "" else round end)
  ] | map(tostring) | join("\u001f")' <<<"$payload"
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

usage=""
if [[ -n "$five_pct" ]]; then
  usage+=" · 5h $five_pct%"
  [[ -z "$five_reset" ]] || usage+=" ↻$(date -d "@$five_reset" +%H:%M)"
fi
[[ -z "$week_pct" ]] || usage+=" · 7d $week_pct%"

printf '%s%s · ctx %s%s · %s\n' "$model" "${effort:+ ($effort)}" "$used" "$usage" "$location"
