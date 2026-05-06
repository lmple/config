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
