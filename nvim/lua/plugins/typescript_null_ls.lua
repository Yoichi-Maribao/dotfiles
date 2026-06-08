-- Prettier/ESLint の設定は none-ls.lua に統合済み
-- mason-null-ls のハンドラーは自動検出に任せる
return {
  "jay-babu/mason-null-ls.nvim",
  opts = {
    ensure_installed = { "prettier", "eslint_d" },
  },
}
