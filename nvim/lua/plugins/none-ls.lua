-- Customize None-ls sources
-- ESLint is handled by astrocommunity.pack.eslint (LSP-based)

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null-ls"

    local biome_files = { "biome.json", "biome.jsonc" }

    local prettier_files = {
      ".prettierrc",
      ".prettierrc.json",
      ".prettierrc.js",
      ".prettierrc.mjs",
      ".prettierrc.cjs",
      ".prettierrc.yaml",
      ".prettierrc.yml",
      ".prettierrc.toml",
      "prettier.config.js",
      "prettier.config.mjs",
      "prettier.config.cjs",
    }

    local has_biome = function(utils) return utils.root_has_file(biome_files) end
    local has_prettier = function(utils)
      if has_biome(utils) then return false end
      return utils.root_has_file(prettier_files)
    end

    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      -- Biome: biome.json がある場合のみ有効
      null_ls.builtins.formatting.biome.with {
        only_local = "node_modules/.bin",
        condition = has_biome,
      },
      -- Prettier: prettier設定がある場合に有効、biome.json がある場合は無効
      null_ls.builtins.formatting.prettier.with { condition = has_prettier },
    })
  end,
}
