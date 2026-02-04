-- nvim/lua/core/options.lua

local opt = vim.opt
local g = vim.g

---------------------------------------------------------------------
-- Leader keys (must be set early)
---------------------------------------------------------------------
g.mapleader = " "
g.maplocalleader = "\\"

---------------------------------------------------------------------
-- UI / Display
---------------------------------------------------------------------
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true

--opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.breakindentopt = "shift:2"
opt.showbreak = "↳ "



opt.fillchars = { eob = " " }     -- hide ~ at end of buffer
opt.shortmess:append("I")         -- no intro message

opt.laststatus = 3                -- global statusline
opt.showmode = false              -- hide -- INSERT --

---------------------------------------------------------------------
-- Tabs / Indentation
---------------------------------------------------------------------
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.smartindent = true
opt.showtabline = 2

---------------------------------------------------------------------
-- Search
---------------------------------------------------------------------
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

---------------------------------------------------------------------
-- Window / Splits
---------------------------------------------------------------------
opt.splitright = true
opt.splitbelow = true

---------------------------------------------------------------------
-- Performance / Responsiveness
---------------------------------------------------------------------
opt.updatetime = 250
opt.timeoutlen = 400

---------------------------------------------------------------------
-- Clipboard
---------------------------------------------------------------------
opt.clipboard = "unnamedplus"

---------------------------------------------------------------------
-- Completion
---------------------------------------------------------------------
opt.completeopt = { "menu", "menuone", "noselect" }

---------------------------------------------------------------------
-- Undo
---------------------------------------------------------------------
opt.undofile = true

---------------------------------------------------------------------
-- Providers
---------------------------------------------------------------------
-- Python
g.python3_host_prog = vim.fn.expand("~/.venvs/nvim/bin/python")

-- Disable unused providers (startup speed)
g.loaded_node_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0


-- Add 'A' to shortmess to ignore the "ATTENTION" message when a swap file exists
opt.shortmess:append("A")