-- The AstroCommunity lean pack configures lean.nvim through `opts`, which makes
-- lazy.nvim call the deprecated `require("lean").setup()`. lean.nvim now reads
-- `vim.g.lean_config` and activates itself on Lean files, so set that before
-- load and skip setup. The pack's `lsp.on_attach` is dropped on purpose:
-- lean.nvim no longer reads it, and AstroLSP attaches via its own LspAttach.

---@type LazySpec
return {
  "Julian/lean.nvim",
  init = function() vim.g.lean_config = { mappings = true } end,
  config = function() end,
}
