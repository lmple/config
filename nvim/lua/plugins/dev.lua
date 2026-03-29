return {
  -- Pyright LSP for Python
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {},
        ruff = {},
      },
    },
  },

  -- Black + Ruff formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "black", "ruff" },
      },
    },
  },

  -- Auto-install Python tools via Mason
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "black", "ruff", "mypy", "pylint" },
    },
  },

  -- Coq proof assistant
  { "whonore/Coqtail", ft = "coq" },

  -- TLA+ syntax highlighting
  { "hwayne/tla.vim", ft = "tla" },

  -- Jupynium: sync nvim buffer with Jupyter in browser
  {
    "kiyoon/jupynium.nvim",
    build = "pip install --user .",
    cmd = { "JupyniumStartAndAttachToServer", "JupyniumAttachToServer" },
    dependencies = {
      "rcarriga/nvim-notify",
      "stevearc/dressing.nvim",
    },
  },

  -- mypy + pylint via nvim-lint
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "mypy", "pylint" },
      },
    },
  },

  -- Python DAP adapter
  {
    "mfussenegger/nvim-dap-python",
    dependencies = { "mfussenegger/nvim-dap" },
    ft = "python",
    config = function()
      require("dap-python").setup("python")
    end,
  },

  -- Python virtual environment selector
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
    },
    opts = {},
    keys = {
      { "<leader>vs", "<cmd>VenvSelect<cr>", desc = "Select Python venv" },
      { "<leader>vc", "<cmd>VenvSelectCached<cr>", desc = "Select cached Python venv" },
    },
  },

  -- Neotest + Python adapter
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "pytest",
        },
      },
    },
    keys = {
      { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle test summary" },
      { "<leader>to", function() require("neotest").output_panel.toggle() end, desc = "Toggle test output" },
    },
  },
}
