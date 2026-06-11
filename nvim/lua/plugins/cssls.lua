-- Tailwind v4 の @theme/@utility/@apply 等を cssls が "Unknown at rule" にしないよう抑制
---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    config = {
      cssls = {
        settings = {
          css = { lint = { unknownAtRules = "ignore" } },
          scss = { lint = { unknownAtRules = "ignore" } },
          less = { lint = { unknownAtRules = "ignore" } },
        },
      },
    },
  },
}
