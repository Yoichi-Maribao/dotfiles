-- Biome が担当するファイル種別で LSP 側フォーマッタを無効化し、フォーマットを biome に一本化する
-- (mason 導入済みの LSP は自動で有効化されるため、jsonls が tsconfig.json 等を
--  biome と違う形に整形してしまい、biome check と毎回衝突していた)
-- 補完・診断・schema validation はそのまま生きる。無効になるのはフォーマットのみ。
---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    formatting = {
      disabled = {
        "jsonls",
        "vtsls",
        "cssls",
      },
    },
  },
}
