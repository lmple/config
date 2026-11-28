# Global Preferences

The rules shared with the other agents (opencode, pi), linked there by
install.sh from agents/AGENTS.md in the config repo:
@~/.claude/AGENTS.md

Claude Code only: see @~/.claude/RTK.md for the rtk command proxy.

Write shell commands in the form rtk's hook would rewrite them to, so auto
mode reviews the command that actually runs instead of asking for it twice:
`rtk git …`, `rtk ls`, `rtk read FILE` (for `cat`; `head` is
`rtk read FILE --head-lines N`), `rtk grep`, `rtk find`, `rtk diff`,
`rtk du`, in every part of a pipe or `;`/`&&` chain. When unsure,
`rtk rewrite 'CMD'` prints the form the hook would run. The exception is
jq: `rtk jq` prints a compressed view, not JSON, and hides jq's failures, so
use `rtk proxy jq` whenever its output feeds a pipe or a file.

Hand a task to the `implementer` subagent (Sonnet) when it is small and fully
specified: the files, the change, how to verify it. Keep design, debugging
and anything ambiguous here. Delegate only when doing the work costs more
than describing it; write a few lines yourself. Review its work yourself,
read the diff and rerun the checks, before reporting the task done.
Independent delegated tasks can run in parallel, each implementer with
`isolation: "worktree"` so their edits can't collide. Review each worktree's
diff, then apply it to the main tree with `git diff | git apply`, one at a
time; nothing is committed, as usual.
