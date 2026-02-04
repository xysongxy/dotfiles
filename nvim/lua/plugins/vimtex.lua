-- nvim/lua/plugins/vimtex.lua

-- =========================
-- Viewer (Skim) + SyncTeX
-- =========================
vim.g.vimtex_view_method = "skim"
vim.g.vimtex_view_skim_sync = 1
vim.g.vimtex_view_skim_activate = 1
-- vim.g.vimtex_view_automatic = 1

-- Auto-open/update Skim after a successful compilation
vim.api.nvim_create_autocmd("User", {
  pattern = { "VimtexEventCompileSuccess", "VimtexCompileSuccess" },
  callback = function()
    vim.defer_fn(function()
      if vim.fn.exists(":VimtexView") == 2 then
        vim.cmd("VimtexView")
      end
    end, 100)
  end,
})
vim.g.vimtex_imaps_enabled = 0

-- =========================
-- Compiler (latexmk)
-- =========================
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_compiler_autostart = 0
vim.g.vimtex_compiler_write = 1

vim.g.vimtex_compiler_latexmk = {
  options = {
    "-synctex=1",
    "-interaction=nonstopmode",
    "-file-line-error",
    "-time",
  },
  engines = { _ = "-pdf" },
  continuous = 0,
  build_dir = "build",
}

vim.g.vimtex_clean_on_exit = 0
vim.g.vimtex_view_automatic = 0  -- optional, but feels faster


-- =========================
-- QoL
-- =========================
vim.g.vimtex_fold_enabled = 0
vim.g.vimtex_clean_on_exit = 1

-- =========================
-- Helpers: engine + shell-escape
-- =========================
local function set_engine(engine_flag, name)
  vim.g.vimtex_compiler_latexmk.engines._ = engine_flag
  vim.notify(("VimTeX engine set to: %s (%s)"):format(name, engine_flag))
end

local function set_shell_escape(on)
  local base = {
    "-synctex=1",
    "-interaction=nonstopmode",
    "-file-line-error",
  }
  if on then
    table.insert(base, "-shell-escape")
  end
  vim.g.vimtex_compiler_latexmk.options = base
  vim.notify("VimTeX latexmk shell-escape: " .. (on and "ON" or "OFF"))
end

vim.api.nvim_create_user_command("TexEnginePdflatex", function() set_engine("-pdf", "pdflatex") end, {})
vim.api.nvim_create_user_command("TexEngineXelatex",  function() set_engine("-xelatex", "xelatex") end, {})
vim.api.nvim_create_user_command("TexEngineLualatex", function() set_engine("-lualatex", "lualatex") end, {})

vim.api.nvim_create_user_command("TexShellEscapeOn",  function() set_shell_escape(true) end, {})
vim.api.nvim_create_user_command("TexShellEscapeOff", function() set_shell_escape(false) end, {})

vim.api.nvim_create_user_command("TexPdflatexShell", function()
  set_engine("-pdf", "pdflatex")
  set_shell_escape(true)
end, {})

-- =========================
-- Keymaps
-- =========================
local map = vim.keymap.set
local opts = { silent = true, noremap = true }
map("n", "<F5>", function()
  vim.cmd("silent! write")
  vim.cmd("VimtexCompile")
end, opts)

map("n", "<F6>", "<cmd>VimtexView<CR>", opts)
map("n", "<F7>", "<cmd>VimtexClean<CR>", opts)

-- =========================
-- Quickfix: open ONLY on errors, and move to right
-- =========================
vim.g.vimtex_quickfix_mode = 0 -- we control when qf opens

local function open_qf_only_if_error()
  local qf = vim.fn.getqflist()
  if not qf or #qf == 0 then return end

  for _, it in ipairs(qf) do
    if it.valid == 1 and (it.type == "E" or it.type == "e") then
      vim.cmd("copen")
      vim.cmd("wincmd L")
      vim.cmd("vertical resize 40")
      return
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = { "VimtexCompileFailed", "VimtexEventCompileFailed" },
  callback = function()
    vim.defer_fn(open_qf_only_if_error, 50)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.cmd("wincmd L")
    vim.cmd("vertical resize 40")
  end,
})
