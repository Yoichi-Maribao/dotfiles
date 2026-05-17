return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  opts = {
    cmdline = {
      enabled = true,
      view = "cmdline_popup",
    },
    messages = {
      enabled = true,
      view = "notify",
    },
    lsp = {
      signature = {
        enabled = false,
      },
      hover = {
        enabled = false,
      },
    },
  },
}
