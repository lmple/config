# TypeScript AstroNvim Configuration Design

**Date:** 2026-05-06
**Status:** Approved

## Goal

Configure AstroNvim v6 for TypeScript/JavaScript development using three astrocommunity packs:
- **`astrocommunity.pack.typescript`** — vtsls LSP, inlay hints, tsc.nvim, package-info.nvim
- **`astrocommunity.pack.prettier`** — prettierd formatter via conform.nvim
- **`astrocommunity.pack.eslint`** — eslint as a second LSP for linting

## File Changes

### `lua/community.lua`
Add three pack imports alongside the existing `lua` and `python` imports:

```lua
{ import = "astrocommunity.pack.typescript" },
{ import = "astrocommunity.pack.prettier" },
{ import = "astrocommunity.pack.eslint" },
```

This is the only file change. No new plugin file is needed.

## What Each Pack Provides

### typescript pack
- `vtsls` LSP (wraps typescript-language-server) with inlay hints (param names, return types, variable types) enabled by default
- `gs` buffer-local keymap → go-to-source-definition (vtsls-specific)
- `:TSC` command via `tsc.nvim` for project-wide type-checking
- `package-info.nvim` — inline package version info in `package.json` buffers
- Treesitter parsers: `javascript`, `typescript`, `tsx`, `jsdoc`

### prettier pack
- Installs `prettierd` via mason-tool-installer
- Wires prettierd into `conform.nvim` for format-on-save across: js, ts, tsx, json, jsonc, yaml, markdown, html, css, scss, less, graphql, svelte, astro
- `conform.nvim` is installed as a new dependency (coexists with `none-ls.nvim` — they handle different filetypes: prettier → TS/JS, black → Python)

### eslint pack
- Installs `eslint-lsp` via mason-tool-installer
- Runs as an LSP alongside vtsls; diagnostics respect project-level `eslint.config.js` / `.eslintrc.*`

## Non-Changes

- `lua/plugins/mason.lua` — packs register their own tools via mason-tool-installer internally
- `lua/plugins/none-ls.lua` — black and mypy remain unchanged (Python only)
- All other plugin files remain untouched

## Prerequisites

- `node` and `npm` must be available on PATH for Mason to install vtsls and prettierd
- After enabling, run `:Lazy sync` then `:MasonToolsInstall` inside nvim

## Out of Scope

- Per-project prettier config (handled via `.prettierrc` in each project)
- ESLint rule configuration (handled via `eslint.config.js` in each project)
