-- ~/.config/nvim/init.lua

-- 1) Bootstrap lazy.nvim (MUST happen before require("lazy").setup)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)



-- Core settings
require("core.options")
require("core.terminal")
require("core.keymaps")
require("core.autocmds")

-- Plugins 
require("plugins.init")
