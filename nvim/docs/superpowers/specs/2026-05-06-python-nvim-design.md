# Python AstroNvim Configuration Design

**Date:** 2026-05-06
**Status:** Approved

## Goal

Configure AstroNvim v6 for Python development using:
- **pyright** as the language server (LSP)
- **black** as the formatter (format-on-save)
- **ruff** for linting and import diagnostics
- **mypy** for type checking
- **uv** venv detection via `venv-selector.nvim`

## File Changes

### `lua/community.lua`
Remove the `if true then return {} end` guard. Add `astrocommunity.pack.python` import alongside the existing `astrocommunity.pack.lua`. The pack auto-installs pyright, ruff, debugpy, and `venv-selector.nvim` via Mason and wires them into AstroNvim's LSP and conform pipelines.

### `lua/plugins/mason.lua`
Remove the guard. Add `black` and `mypy` to `ensure_installed`. These are installed globally by Mason so they are always available regardless of which venv is active.

### `lua/plugins/python.lua` (new file)
Three plugin overrides, all scoped to Python:

1. **conform.nvim override** — set `formatters_by_ft.python = { "black" }`. This overrides the pack's default of ruff-format, ensuring black is always the formatter.

2. **nvim-lint override** — add `mypy` to `linters_by_ft.python`. Ruff diagnostics are already provided by pyright/ruff-lsp via the pack; mypy adds static type checking on top.

3. **venv-selector.nvim override** — configure it to search ancestor directories for `.venv` (uv's default location). Set `auto_refresh = true` so it activates automatically on `BufEnter` for Python files.

## Environment Detection Flow

**Normal flow (nvim launched from activated env):**
- User runs `source .venv/bin/activate` in terminal
- Launches nvim — pyright reads `python` from PATH, which is the venv's interpreter
- All tools (black, mypy, ruff) also run from the venv's PATH

**Mid-session env switch:**
- User runs `:VenvSelect` inside nvim
- venv-selector finds `.venv` directories in ancestor dirs
- Restarts pyright with the new interpreter

## What Is Not Changed

- `lua/plugins/astrolsp.lua` — stays disabled (guard intact); format-on-save is already enabled globally by AstroNvim defaults
- `lua/plugins/none-ls.lua` — stays disabled; formatting goes through conform, linting through nvim-lint
- `lua/plugins/user.lua` — stays disabled; Python config is isolated in `python.lua`

## Out of Scope

- Debugger configuration (debugpy is installed by the pack but not configured here)
- Per-project pyright settings (handled via `pyrightconfig.json` in each project)
