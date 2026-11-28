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
`rtk rewrite 'CMD'` prints the form the hook would run.

Hand a task to the `implementer` subagent (Sonnet) when it is small and fully
specified: the files, the change, how to verify it. Keep design, debugging
and anything ambiguous here. Delegate only when doing the work costs more
than describing it; write a few lines yourself. Review its work yourself,
read the diff and rerun the checks, before reporting the task done.
