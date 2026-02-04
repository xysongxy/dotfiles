-- nvim/ftplugin/tex.lua


vim.opt_local.wrap = true
vim.opt_local.spell = true
vim.opt_local.conceallevel = 2
vim.opt_local.textwidth = 0

-- buffer-local vimtex mappings (only active in tex buffers)
vim.keymap.set("n", "<localleader>ll", "<cmd>VimtexCompile<cr>", { buffer = true, desc = "Vimtex compile" })
vim.keymap.set("n", "<localleader>lv", "<cmd>VimtexView<cr>", { buffer = true, desc = "Vimtex view" })
