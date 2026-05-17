-- luarocks path for image.nvim (magick)
package.path = package.path .. ";" .. vim.fn.expand "$HOME" .. "/.luarocks/share/lua/5.1/?.lua"
package.path = package.path .. ";" .. vim.fn.expand "$HOME" .. "/.luarocks/share/lua/5.1/?/init.lua"
package.cpath = package.cpath .. ";" .. vim.fn.expand "$HOME" .. "/.luarocks/lib/lua/5.1/?.so"

-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"
require "polish"

-- neo-tree
vim.keymap.set("n", "<C-t>", ":Neotree toggle<CR>")

-- cmdheight
vim.opt.cmdheight = 0

-- disable statusline
vim.opt.laststatus = 0

-- camel <-> kebab <-> snake
-- Normal mode mappings
vim.keymap.set("n", "<Space>c", [[viw:s/\%V\(_\|-\)\(.\)/\u\2/g<CR>]], { noremap = true, silent = true })
vim.keymap.set("n", "<Space>_", [[viw:s/\%V\([A-Z]\)/_\l\1/g<CR>]], { noremap = true, silent = true })
vim.keymap.set("n", "<Space>-", [[viw:s/\%V\([A-Z]\)/-\l\1/g<CR>]], { noremap = true, silent = true })

-- Visual mode mappings
vim.keymap.set("x", "<Space>c", [[:s/\%V\(_\|-\)\(.\)/\u\2/g<CR>]], { noremap = true, silent = true })
vim.keymap.set("x", "<Space>_", [[:s/\%V\([A-Z]\)/_\l\1/g<CR>]], { noremap = true, silent = true })
vim.keymap.set("x", "<Space>-", [[:s/\%V\([A-Z]\)/-\l\1/g<CR>]], { noremap = true, silent = true })
