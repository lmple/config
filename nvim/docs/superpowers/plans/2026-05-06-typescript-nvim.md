# TypeScript AstroNvim Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable TypeScript/JavaScript development in AstroNvim v6 with vtsls LSP, prettier formatting, and eslint linting via three astrocommunity pack imports.

**Architecture:** Add three pack imports to `lua/community.lua`. The packs self-configure via `optional = true` specs — they hook into mason-tool-installer, conform.nvim, and astrolsp without requiring a separate plugin file. conform.nvim is introduced as a new dependency (coexists with none-ls, which handles Python).

**Tech Stack:** AstroNvim v6, astrocommunity, vtsls, prettierd (conform.nvim), eslint-lsp

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lua/community.lua` | Modify | Add typescript, prettier, eslint pack imports |

---

### Task 1: Add TypeScript, Prettier, and ESLint community packs

**Files:**
- Modify: `lua/community.lua`

- [ ] **Step 1: Add the three pack imports**

Replace the entire file content with:

```lua
---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.prettier" },
  { import = "astrocommunity.pack.eslint" },
}
```

- [ ] **Step 2: Verify Lua syntax**

Run: `luac -p ~/.config/nvim/lua/community.lua`
Expected: No output (silent = success).

- [ ] **Step 3: Confirm file content**

Read the file and verify:
- No `if true then return {} end` guard (was already removed for the Python pack)
- All five pack imports present: `lua`, `python`, `typescript`, `prettier`, `eslint`
- No extra additions

---

## Post-Install Steps (manual, inside nvim)

After the file change, the following must be run interactively:

1. `:Lazy sync` — downloads typescript/prettier/eslint pack dependencies (vtsls, conform.nvim, prettierd, eslint-lsp)
2. `:MasonToolsInstall` — installs vtsls, prettierd, eslint-lsp, js-debug-adapter binaries

## Verification Checklist

After `:Lazy sync` and `:MasonToolsInstall`, open a `.ts` file and confirm:

- [ ] `:LspInfo` shows `vtsls` active
- [ ] `:LspInfo` shows `eslint` active
- [ ] Saving a `.ts` file runs prettier (formatting applied)
- [ ] Inlay hints visible (param names, return types)
- [ ] `gs` navigates to source definition
- [ ] `:TSC` runs project-wide type checking
- [ ] Opening `package.json` shows inline package versions
