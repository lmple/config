# Python AstroNvim Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure AstroNvim v6 for Python development with pyright, black, ruff, mypy, and uv venv detection.

**Architecture:** Enable `astrocommunity.pack.python` for pyright + ruff LSP + venv-selector, configure `none-ls.nvim` (already installed) for black formatting and mypy diagnostics, and disable ruff's formatting capability so black is the sole formatter.

**Tech Stack:** AstroNvim v6, none-ls.nvim, mason-tool-installer.nvim, astrocommunity, venv-selector.nvim

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lua/community.lua` | Modify (remove guard) | Pull in the community python pack (pyright, ruff LSP, debugpy, venv-selector) |
| `lua/plugins/mason.lua` | Modify (remove guard) | Ensure black + mypy are always installed via Mason |
| `lua/plugins/none-ls.lua` | Modify (remove guard) | Configure black as Python formatter, mypy as type-checker |
| `lua/plugins/python.lua` | Create | Disable ruff's LSP formatting, add `:VenvSelect` keybinding |

---

### Task 1: Enable community Python pack

**Files:**
- Modify: `lua/community.lua`

- [ ] **Step 1: Remove the guard and add the python pack import**

Replace the entire file content with:

```lua
---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.python" },
}
```

- [ ] **Step 2: Launch nvim and verify no startup errors**

Run: `nvim --headless "+Lazy sync" +qa 2>&1 | head -20`

Expected: No `Error` lines. The sync downloads the python pack dependencies (pyright, ruff, venv-selector, debugpy).

- [ ] **Step 3: Open nvim and verify pyright attaches to a Python file**

```bash
nvim /tmp/test.py
```

Inside nvim, run `:LspInfo`. Expected: `pyright` shown as an active client for the buffer.

- [ ] **Step 4: Commit**

```bash
git -C ~/.config/nvim add lua/community.lua
git -C ~/.config/nvim commit -m "feat(python): enable astrocommunity python pack"
```

---

### Task 2: Add black and mypy to Mason

**Files:**
- Modify: `lua/plugins/mason.lua`

- [ ] **Step 1: Remove the guard and add Python tools to ensure_installed**

Replace the entire file content with:

```lua
---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- Lua
        "lua-language-server",
        "stylua",
        -- Python
        "black",
        "mypy",
        "debugpy",
        -- Other
        "tree-sitter-cli",
      },
    },
  },
}
```

- [ ] **Step 2: Open nvim and trigger Mason install**

```bash
nvim
```

Inside nvim, run `:MasonToolsInstall`. Expected: black and mypy appear in the Mason log as installed.

Verify with `:Mason` — both `black` and `mypy` should show a checkmark.

- [ ] **Step 3: Commit**

```bash
git -C ~/.config/nvim add lua/plugins/mason.lua
git -C ~/.config/nvim commit -m "feat(python): install black and mypy via mason"
```

---

### Task 3: Configure none-ls for black formatting and mypy diagnostics

**Files:**
- Modify: `lua/plugins/none-ls.lua`

- [ ] **Step 1: Remove the guard and wire up black + mypy**

Replace the entire file content with:

```lua
---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null-ls"
    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      -- Format Python with black
      null_ls.builtins.formatting.black,
      -- Type-check with mypy; prefer project's own mypy if .venv exists
      null_ls.builtins.diagnostics.mypy.with {
        prefer_local = ".venv/bin",
      },
    })
  end,
}
```

The `prefer_local = ".venv/bin"` makes mypy use the project venv's mypy binary when present, falling back to the Mason-installed one. This ensures mypy sees the project's installed packages.

- [ ] **Step 2: Open a Python file and verify black formats on save**

```bash
echo 'x=1+2' > /tmp/test.py
nvim /tmp/test.py
```

Inside nvim: press `<Leader>lf` (force format) or save with `:w`.
Expected: the buffer content becomes `x = 1 + 2` (black-formatted).

- [ ] **Step 3: Verify none-ls sources are active**

Inside nvim with a Python file open, run `:NullLsInfo`.
Expected: `black` shown under formatters, `mypy` shown under diagnostics.

- [ ] **Step 4: Commit**

```bash
git -C ~/.config/nvim add lua/plugins/none-ls.lua
git -C ~/.config/nvim commit -m "feat(python): add black formatter and mypy diagnostics via none-ls"
```

---

### Task 4: Disable ruff LSP formatting and configure venv-selector

**Files:**
- Create: `lua/plugins/python.lua`

- [ ] **Step 1: Create the file**

```lua
---@type LazySpec
return {
  -- Disable ruff's formatting so black (via none-ls) is the sole formatter.
  -- Ruff diagnostics still work through its LSP.
  {
    "AstroNvim/astrolsp",
    opts = {
      formatting = {
        disabled = { "ruff" },
      },
    },
  },

  -- Add :VenvSelect keybinding for mid-session venv switching.
  -- venv-selector is installed by astrocommunity.pack.python and auto-detects
  -- .venv directories (uv's default location) in ancestor directories.
  {
    "linux-cultist/venv-selector.nvim",
    keys = {
      { "<Leader>cv", "<Cmd>VenvSelect<CR>", desc = "Select Python venv" },
    },
  },
}
```

- [ ] **Step 2: Verify ruff does not format on save**

```bash
echo 'x=1+2' > /tmp/test.py
nvim /tmp/test.py
```

Inside nvim, run `:LspInfo` — ruff should be listed as active.
Save the file with `:w`. The formatter should be black (output: `x = 1 + 2`), not ruff-format.
Run `:NullLsInfo` to confirm black is the active formatter.

> If ruff still formats, the server may be registered as `ruff_lsp` instead of `ruff`.
> In that case, change `disabled = { "ruff" }` to `disabled = { "ruff_lsp" }` in `python.lua`.

- [ ] **Step 3: Verify venv-selector finds uv venv**

```bash
cd /tmp && uv init testproject && cd testproject && uv venv
nvim src/testproject/__init__.py
```

Inside nvim, press `<Leader>cv`. Expected: a picker appears showing `.venv` in the project root.
Select it. Run `:LspInfo` — pyright should now show the venv Python path.

- [ ] **Step 4: Commit**

```bash
git -C ~/.config/nvim add lua/plugins/python.lua
git -C ~/.config/nvim commit -m "feat(python): disable ruff formatting, add venv-selector keybinding"
```

---

## Verification Checklist

After all tasks are complete, open a real Python project and confirm:

- [ ] `:LspInfo` shows `pyright` active
- [ ] Saving a `.py` file runs black (formatting applied)
- [ ] `:NullLsInfo` shows `black` + `mypy` active
- [ ] `<Leader>cv` opens the venv picker
- [ ] Selecting the uv `.venv` updates pyright's Python path (visible in `:LspInfo`)
- [ ] Ruff diagnostics appear in the gutter (squiggles for lint errors)
- [ ] Mypy type errors appear in the gutter
