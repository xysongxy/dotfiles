-- nvim/lua/plugins/bufferline.lua

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function tab_bufs()
  -- scope.nvim keeps a tab-local list here
  if type(vim.t.bufs) == "table" and #vim.t.bufs > 0 then
    return vim.t.bufs
  end
  -- fallback
  return vim.fn.tabpagebuflist()
end

local function is_dashboard(bufnr)
  return vim.bo[bufnr].filetype == "dashboard"
end

local function is_listed_showable(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if not vim.bo[bufnr].buflisted then return false end

  local bt = vim.bo[bufnr].buftype
  local ft = vim.bo[bufnr].filetype
  local name = vim.api.nvim_buf_get_name(bufnr) or ""

  -- Hide utility buffers
  if bt == "quickfix" or ft == "qf" then return false end
  if bt == "terminal" or name:match("^term://") then return false end
  if name:match(":radian") or name:match("ipython") then return false end
  if ft == "lazy" or ft == "neo-tree" then return false end

  return true
end

local function make_scratch()
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.buflisted = false
  vim.bo.modifiable = false
end

---------------------------------------------------------------------
-- Safe buffer delete
---------------------------------------------------------------------
function _G.tab_safe_bdelete(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cur = vim.api.nvim_get_current_buf()
  local is_current = (cur == bufnr)

  local candidates = {}
  for _, b in ipairs(tab_bufs()) do
    if b ~= bufnr and is_listed_showable(b) then
      table.insert(candidates, b)
    end
  end

  local function pick_next()
    if #candidates == 0 then return nil end
    for _, b in ipairs(candidates) do
      if not is_dashboard(b) then return b end
    end
    return candidates[1]
  end

  if is_current then
    local nextb = pick_next()
    if nextb then
      pcall(vim.api.nvim_set_current_buf, nextb)
    else
      make_scratch()
    end
  end

  pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
end

---------------------------------------------------------------------
-- Bufferline setup
---------------------------------------------------------------------
require("bufferline").setup({
  options = {
    mode = "buffers",
    numbers = "none",
    close_command = function(bufnr) _G.tab_safe_bdelete(bufnr) end,
    right_mouse_command = function(bufnr) _G.tab_safe_bdelete(bufnr) end,
    indicator = { style = "icon", icon = "▎" },
    buffer_close_icon = "󰅖",
    modified_icon = "●",
    close_icon = "",
    diagnostics = "nvim_lsp",
    offsets = {
      { filetype = "neo-tree", text = "Explorer", highlight = "Directory", text_align = "left" },
    },
    always_show_bufferline = true,
    separator_style = "slant",
    custom_filter = function(bufnr, _)
      -- 1. Explicitly filter out dashboard buffers
      if is_dashboard(bufnr) then return false end

      -- 2. Standard checks
      if not is_listed_showable(bufnr) then return false end
      return vim.tbl_contains(tab_bufs(), bufnr)
    end,
  },
})