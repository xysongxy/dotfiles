-- lua/core/terminal.lua
local M = {}
local followers = {}

-- Keep background REPL windows at the latest output without taking focus.
-- A focused terminal is left alone so its scrollback can be read normally.
function M.follow(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "terminal" then
    return
  end

  if followers[buf] then
    followers[buf]()
    return
  end

  local pending = false
  local function queue_scroll()
    if pending then
      return
    end
    pending = true

    -- Buffer update callbacks run under textlock; move the view afterwards.
    vim.schedule(function()
      pending = false
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      local current = vim.api.nvim_get_current_win()
      local last = vim.api.nvim_buf_line_count(buf)
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= current and vim.api.nvim_win_get_buf(win) == buf then
          -- Setting the cursor scrolls the window without leaving Terminal mode.
          vim.api.nvim_win_set_cursor(win, { last, 0 })
        end
      end
    end)
  end

  if vim.api.nvim_buf_attach(buf, false, {
    on_lines = queue_scroll,
    on_detach = function()
      followers[buf] = nil
    end,
  }) then
    followers[buf] = queue_scroll
    queue_scroll()
  end
end

local function is_repl(buf)
  if vim.bo[buf].buftype ~= "terminal" then
    return false
  end

  local command = vim.api.nvim_buf_get_name(buf):match("//%d+:(.*)$") or ""
  local program = (command:match("^%s*(%S+)") or ""):match("([^/]+)$")
  return program == "radian" or program == "R" or program == "ipython" or program == "ipython3"
end

function M.setup()
  local group = vim.api.nvim_create_augroup("CoreTerminal", { clear = true })

  vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    callback = function(ev)
      -- Never show terminals in buffer lists (bufferline, :ls, etc.)
      vim.bo[ev.buf].buflisted = false

      -- Terminal UX
      vim.bo[ev.buf].swapfile = false
      vim.bo[ev.buf].bufhidden = "hide"

      vim.wo.number = false
      vim.wo.relativenumber = false
      vim.wo.signcolumn = "no"

      if is_repl(ev.buf) then
        M.follow(ev.buf)
      end

      -- Start in insert mode
      vim.cmd("startinsert")
    end,
  })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    pattern = "term://*",
    callback = function(ev)
      if is_repl(ev.buf) then
        M.follow(ev.buf)
      end
    end,
  })
end

return M
