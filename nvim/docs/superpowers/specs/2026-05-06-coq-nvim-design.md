# Coq AstroNvim Configuration Design

**Date:** 2026-05-06
**Status:** Approved

## Goal

Configure AstroNvim v6 for Coq proof assistant development using:
- **coqtail** (`whonore/coqtail`) for interactive proof stepping
- **coq-lsp** (opam-managed, at `/home/loic/.opam/default/bin/coq-lsp`) for LSP features
- **treesitter** `coq` parser for syntax highlighting of `.v` files
- `<Leader>c*` buffer-local keybindings (replaces coqtail's default `,c*` maps)

## File Changes

### `lua/plugins/treesitter.lua`
Remove the `if true then return {} end` guard. Keep all existing settings (`highlight = true`, `indent = true`, `auto_install = true`). Add `"coq"` to the `ensure_installed` list alongside the existing `"lua"` and `"vim"` parsers.

### `lua/plugins/coq.lua` (new file)
Two plugin specs:

**1. coqtail**
- Loaded lazily on `ft = "coq"` (`.v` files only)
- `init` function sets `vim.g.coqtail_nomap = 1` to disable default `,c*` mappings
- Buffer-local keybindings defined in the `keys` table:

| Key | Command | Description |
|---|---|---|
| `<Leader>cs` | `:CoqStart<CR>` | Start Coq |
| `<Leader>cQ` | `:CoqStop<CR>` | Stop Coq |
| `<Leader>cn` | `:CoqNext<CR>` | Step forward one sentence |
| `<Leader>cu` | `:CoqUndo<CR>` | Step back one sentence |
| `<Leader>cj` | `:CoqToLine<CR>` | Advance/retract to cursor line |
| `<Leader>cG` | `:CoqJumpToEnd<CR>` | Move cursor to end of checked region |

**2. astrolsp override**
- Adds `"coq_lsp"` to `astrolsp.servers` so AstroNvim enables the server via nvim-lspconfig
- Sets `astrolsp.config.coq_lsp.cmd = { "/home/loic/.opam/default/bin/coq-lsp" }` since coq-lsp is opam-managed, not Mason-managed
- Uses function-form `opts` to avoid clobbering existing astrolsp configuration
- If the binary is absent (coq-lsp not yet installed), nvim-lspconfig silently skips attachment

## Prerequisites

- `coqtop` already available at `/home/loic/.opam/default/bin/coqtop` ✓
- `coq-lsp` requires `opam install coq-lsp` before the LSP features work; coqtail works without it

## What Is Not Changed

- `lua/plugins/none-ls.lua` — no Coq formatter exists, nothing to add
- `lua/plugins/mason.lua` — coq-lsp is opam-managed, not Mason-managed
- All other plugin files remain untouched

## Out of Scope

- coq-lsp project-level settings (handled via `.coq-lsp` file or `_CoqProject` in each project)
- Snippet or template support for Coq tactics
