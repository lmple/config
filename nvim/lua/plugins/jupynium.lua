-- Jupynium syncs `*.ju.py` buffers to a Jupyter page in Firefox via geckodriver.
-- It only supports the classic UI, so the default `/nbclassic` URL is kept and
-- relies on the `nbclassic` package next to Notebook 7 in the pyenv Python.
-- Its default keymaps (`<space>x`, `<space>c`, `<space>os`) shadow AstroNvim's
-- `<Leader>x` group, close-buffer and explorer maps in notebook buffers, so the
-- same actions live under a `<Leader>j` group instead. Text objects (`[j`, `]j`,
-- `aj`, `ij`, `<space>jj`) don't collide and stay on the plugin defaults.

local function set_notebook_mappings(buf)
  local cmd = function(name) return "<Cmd>" .. name .. "<CR>" end
  local shared = {
    ["<Leader>jx"] = { cmd "JupyniumExecuteSelectedCells", desc = "Execute selected cells" },
    ["<Leader>jc"] = { cmd "JupyniumClearSelectedCellsOutputs", desc = "Clear selected cells outputs" },
    ["<Leader>js"] = { cmd "JupyniumScrollToCell", desc = "Scroll to cell" },
    ["<Leader>jS"] = { cmd "JupyniumScrollToOutput", desc = "Scroll to output" },
    ["<Leader>jo"] = { cmd "JupyniumToggleSelectedCellsOutputsScroll", desc = "Toggle output scroll" },
  }
  require("astrocore").set_mappings({
    n = vim.tbl_extend("force", shared, {
      ["<Leader>j"] = { desc = "󰠮 Jupynium" },
      ["<Leader>jk"] = { cmd "JupyniumKernelHover", desc = "Kernel hover" },
      ["<PageUp>"] = { cmd "JupyniumScrollUp", desc = "Scroll notebook up" },
      ["<PageDown>"] = { cmd "JupyniumScrollDown", desc = "Scroll notebook down" },
    }),
    x = vim.tbl_extend("force", shared, {
      ["<Leader>j"] = { desc = "󰠮 Jupynium" },
    }),
  }, { buffer = buf })
end

---@type LazySpec
return {
  "kiyoon/jupynium.nvim",
  -- The pyenv shim resolves to the global Python, which also runs Jupyter.
  build = "pip install .",
  event = { "BufReadPre *.ju.*", "BufNewFile *.ju.*" },
  cmd = {
    "JupyniumStartAndAttachToServer",
    "JupyniumStartAndAttachToServerInTerminal",
    "JupyniumAttachToServer",
  },
  opts = {
    use_default_keybindings = false,
  },
  config = function(_, opts)
    require("jupynium").setup(opts)
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = vim.api.nvim_create_augroup("jupynium_user_mappings", { clear = true }),
      pattern = "*.ju.*",
      callback = function(event) set_notebook_mappings(event.buf) end,
    })
  end,
}
