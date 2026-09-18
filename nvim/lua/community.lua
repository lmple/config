-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.bash" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.terraform" },
  { import = "astrocommunity.pack.ansible" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.prettier" },
  { import = "astrocommunity.pack.eslint" },
  { import = "astrocommunity.pack.haskell" },
  { import = "astrocommunity.pack.lean" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.markdown-and-latex.vimtex" },
  -- import/override with your plugins folder
}
