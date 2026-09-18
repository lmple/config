-- Hand-wired LSP client for Quint (`quint-language-server`).
-- No Mason package or astrocommunity pack exists for Quint, so this is
-- configured directly. Requires `quint-language-server` on PATH
-- (`npm i -g @informalsystems/quint-language-server`).

---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = function()
    vim.lsp.config("quint", {
      cmd = { "quint-language-server", "--stdio" },
      filetypes = { "quint" },
      root_markers = { ".git" },
    })
    vim.lsp.enable "quint"
  end,
}
