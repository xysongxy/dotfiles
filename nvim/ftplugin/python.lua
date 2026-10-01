-- nvim/ftplugin/python.lua

vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
vim.opt_local.expandtab = true

-- Fold Python structures using Treesitter and start with every fold closed.
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt_local.foldlevel = 0
vim.opt_local.foldenable = true
