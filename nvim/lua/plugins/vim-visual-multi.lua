---@type LazySpec
return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "BufEnter",
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
      }
    end,
  },
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        n = {
          ["<C-d>"] = false,
        },
        v = {
          ["<C-d>"] = false,
        },
      },
    },
  },
}
