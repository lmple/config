-- astrocommunity.pack.haskell pulls in `haskell-debug-adapter` for DAP support,
-- but its Mason install fails: the from-source cabal build runs `cabal update`
-- against a dead hackage mirror (objects-us-east-1.dream.io -> HTTP 403).
-- haskell-language-server itself installs fine via ghcup, so just drop the
-- debug adapter from what gets auto-installed rather than debugging DAP.

---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(
        function(tool) return tool ~= "haskell-debug-adapter" end,
        opts.ensure_installed
      )
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool) return tool ~= "haskell" end, opts.ensure_installed)
    end,
  },
}
