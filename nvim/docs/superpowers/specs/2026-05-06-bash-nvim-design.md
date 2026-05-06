# Bash AstroNvim Configuration Design

**Date:** 2026-05-06
**Status:** Approved

## Goal

Configure AstroNvim v6 for Bash/Zsh scripting with a single community pack import covering: bashls LSP, shfmt formatter, shellcheck linter, bash treesitter parser, and bash debug adapter.

## File Changes

### `lua/community.lua`
Add one import: `{ import = "astrocommunity.pack.bash" }`

## What the Pack Provides

- **bashls** LSP configured for `sh`, `bash`, and `zsh` filetypes
- **shfmt** formatter via conform.nvim (sh + zsh)
- **shellcheck** linter via nvim-lint (sh + zsh)
- **bash** treesitter parser
- **bash-debug-adapter** for DAP debugging
- All tools installed via mason-tool-installer

## Non-Changes

All other plugin files remain untouched.
