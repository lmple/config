---@type LazySpec
return {
  -- Interactive Coq proof stepping with <Leader>c* keybindings.
  -- NOTE: coqtail_nomap=1 disables ALL default maps including the [[/]]
  -- navigation motions and iP/aP proof text objects, not just the stepping
  -- maps. This is an intentional tradeoff: full control over the keymap
  -- namespace at the cost of those built-in motions.
  {
    "whonore/coqtail",
    ft = "coq",
    init = function()
      vim.g.coqtail_nomap = 1
    end,
    config = function()
      local function set_coq_maps(buf)
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
        end
        map("<Leader>cs", "<Cmd>CoqStart<CR>", "Start Coq")
        map("<Leader>cQ", "<Cmd>CoqStop<CR>", "Stop Coq")
        map("<Leader>cn", "<Cmd>CoqNext<CR>", "Coq step forward")
        map("<Leader>cu", "<Cmd>CoqUndo<CR>", "Coq step back")
        map("<Leader>cj", "<Cmd>CoqToLine<CR>", "Coq advance to cursor")
        map("<Leader>cG", "<Cmd>CoqJumpToEnd<CR>", "Coq cursor to end of checked")
      end
      -- Autocmd for all subsequent coq buffers
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "coq",
        group = vim.api.nvim_create_augroup("CoqtailMappings", { clear = true }),
        callback = function(ev) set_coq_maps(ev.buf) end,
      })
      -- Lazy's ft-trigger fires the FileType event before config runs, so the
      -- autocmd above won't catch the first buffer. Apply maps to it directly.
      if vim.bo.filetype == "coq" then
        set_coq_maps(vim.api.nvim_get_current_buf())
      end
    end,
  },

  -- Register coq-lsp with AstroNvim's LSP system.
  -- coq-lsp is opam-managed; install with: opam install coq-lsp
  -- If the binary is absent, nvim-lspconfig silently skips attachment.
  {
    "AstroNvim/astrolsp",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      table.insert(opts.servers, "coq_lsp")
      opts.config = opts.config or {}
      opts.config.coq_lsp = {
        cmd = { "/home/loic/.opam/default/bin/coq-lsp" },
      }
      return opts
    end,
  },
}
