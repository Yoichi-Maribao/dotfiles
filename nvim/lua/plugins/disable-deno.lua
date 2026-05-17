-- Deno LSP / deno-nvim を無効化（Denoプロジェクトを使わないため）
return {
  { "sigmasd/deno-nvim", enabled = false },
  {
    "AstroNvim/astrolsp",
    optional = true,
    opts = {
      handlers = {
        denols = false,
      },
    },
  },
}
