# Coding instructions

Arch-based Linux (pacman, paru). Languages: Python, Bash, Lean 4, Quint,
TLA+, TypeScript.

## Before and after a task
- Before starting, say what you are about to do and which files you will touch
- After finishing, summarize what changed and why
- If a task is ambiguous, stop and ask before proceeding
- If you are about to touch something outside the agreed scope, stop and ask

## Planning
- An idea that isn't settled yet gets grilled first (the `grilling` skill,
  `/grill-me`): one question at a time until every decision is made
- In a project with an `openspec/` directory, a new feature or a change in
  behaviour starts as an OpenSpec change: propose, apply, then archive once
  it is verified. Small fixes (a typo, a one-line bug) go in directly
- In a project without one, plan in the conversation; don't run
  `openspec init` unless asked
- Debugging: find the root cause before changing code, never fix by guessing

## Code
- Functional style where it makes sense: pure functions, immutable data
  structures, composition over inheritance
- Fail loudly: no silent fallbacks, no swallowed exceptions
- Delete dead code instead of commenting it out; no backwards-compatibility
  shims in my own code
- Comments explain *why*, not *what* the code does

## Verify, per language
- Python: type hints always; `ruff format`, `ruff check`, `mypy` and
  `pytest` pass; use the project's `.venv` when it has one
- Bash: `set -euo pipefail`, every expansion quoted, long options in
  scripts; `shellcheck` is clean
- Lean 4: `lake build` passes, no `sorry` left
- Quint / TLA+: `quint typecheck` and `quint test`, or TLC; a spec change is
  verified once it is model-checked, not just parsed

## Tests
- Every change in behaviour comes with tests, new or updated, and they pass
  before the task counts as done
- A bug fix starts with a test that fails because of the bug
- Never delete, skip or loosen a failing test to get it green: fix the code,
  or ask
- Run the narrowest test while iterating, the full suite at the end
- In a project with no test setup, say so and say how you verified the change
- Ask before adding a test framework: it is a new dependency

## Documentation
- Update the README in the same commit as the change: new commands, flags,
  keybindings, setup steps, changed behaviour
- Python: docstrings on public functions

## Git
- Commit only when asked; never push without asking
- Small commits, one logical change each; never batch unrelated changes
- Messages: `type(scope): summary` (feat, fix, refactor, docs, test, chore),
  with a body that explains why

## Never
- Read or commit secrets: `.env` files, keys, `~/.ssh`, credentials
- Delete anything outside the repo without asking
- Modify CI/CD configuration without explicit instruction
- Add dependencies without asking first
- Reformat files unrelated to the current task
- Mark a task as done without verifying it is actually complete
