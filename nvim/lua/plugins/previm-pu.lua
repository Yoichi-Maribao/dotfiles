return   {
  "Yoichi-Maribao/previm-pu",
  branch = "master",
  lazy = false,
  config = function()
    vim.g.previm_plantuml_imageprefix = 'http://localhost:8888/png/'
    vim.g.vim_markdown_folding_disabled = 1
    vim.g.previm_enable_realtime = 1
    vim.keymap.set('n', '<Leader>p', ':PrevimOpen<CR>')
  end,
}
