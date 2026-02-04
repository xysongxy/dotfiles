-- lua/core/terminal.lua
local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(ev)
      -- Never show terminals in buffer lists (bufferline, :ls, etc.)
      vim.bo[ev.buf].buflisted = false

      -- Terminal UX
      vim.bo[ev.buf].swapfile = false
      vim.bo[ev.buf].bufhidden = "hide"

      vim.wo.number = false
      vim.wo.relativenumber = false
      vim.wo.signcolumn = "no"

      -- Start in insert mode
      vim.cmd("startinsert")
    end,
  })
end

return M
