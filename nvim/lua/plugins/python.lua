---@type LazySpec
return {
  -- Disable ruff's formatting so black (via none-ls) is the sole formatter.
  -- Ruff diagnostics still work through its LSP.
  {
    "AstroNvim/astrolsp",
    opts = function(_, opts)
      opts.formatting = opts.formatting or {}
      opts.formatting.disabled = require("astrocore").list_insert_unique(
        opts.formatting.disabled or {},
        { "ruff" }
      )
      return opts
    end,
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
