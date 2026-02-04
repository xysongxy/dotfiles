-- ~/.config/nvim/lua/plugins/lualine.lua

local M = {}

local function lsp_client()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if not clients or #clients == 0 then
    return ""
  end
  return clients[1].name
end

function M.setup()
  -- Ensure statusline is actually shown (some configs disable it)
  vim.opt.laststatus = 3 -- global statusline

  require("lualine").setup({
    options = {
      theme = "nord",
      globalstatus = true,
      icons_enabled = true,
      component_separators = { left = "│", right = "│" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = {
        statusline = { "dashboard", "NvimTree", "neo-tree", "lazy" },
      },
    },

    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff" },
      lualine_c = {
        { "filename", path = 1 }, -- relative path
      },
      lualine_x = {
        { lsp_client, icon = "" },
        "encoding",
        "filetype",
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },

    inactive_sections = {
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "location" },
    },
  })
end

return M
