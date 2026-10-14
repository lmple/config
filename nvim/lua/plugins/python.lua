-- AstroNvim starts every language server installed in Mason. Keep basedpyright
-- as the only Python type checker: overlapping ones duplicate diagnostics,
-- hovers and completions. A `false` handler keeps them off even if reinstalled.

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  opts = {
    handlers = {
      pyrefly = false,
      ty = false,
    },
  },
}
