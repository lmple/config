-- No LSP server exists for TLA+; treesitter highlighting is configured in
-- treesitter.lua. These keymaps shell out to the local tla2tools.jar for
-- model checking and PlusCal translation.

local tla2tools = vim.fn.expand "~/.local/lib/tlaplus/tla2tools.jar"

---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = {
    mappings = {
      n = {
        ["<Leader>tc"] = {
          function()
            vim.cmd("split | terminal java -cp " .. tla2tools .. " tlc2.TLC " .. vim.fn.expand "%")
          end,
          desc = "Run TLC model checker on current file",
        },
        ["<Leader>tp"] = {
          function()
            vim.cmd("split | terminal java -cp " .. tla2tools .. " pcal.trans " .. vim.fn.expand "%")
          end,
          desc = "Translate PlusCal in current file",
        },
      },
    },
  },
}
