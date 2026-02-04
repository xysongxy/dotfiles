-- lua/plugins/dashboard.lua
local dashboard = require("dashboard")

-- Optional: tighter vertical spacing between sections (works well with hyper)
vim.g.dashboard_padding = 1

dashboard.setup({
  theme = "hyper",
  config = {
    width = 80,

    header = {
      " ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
      " ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
      " ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
      " ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
      " ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
      " ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
      "",
    },

    shortcut = {
      { desc = " New file",  group = "Number", key = "n", action = "enew" },
      { desc = " Lazy",      group = "Number", key = "l", action = "Lazy" },
      { desc = " Find file", group = "Number", key = "f", action = "Telescope find_files" },
      { desc = " Find word", group = "Number", key = "w", action = "Telescope live_grep" },
    },

    -- Make "Recent projects" narrower-feeling: fewer entries + shorter icon/label spacing
    project = {
      enable = true,
      limit = 6,
      icon = " ",
      label = " Recent projects",
      action = function(path)
        vim.cmd("cd " .. vim.fn.fnameescape(path))
        require("telescope.builtin").find_files({ cwd = path })
      end,
    },

    -- Make "Most recent files" narrower-feeling: fewer entries + shorter icon/label spacing
    mru = {
      enable = true,
      limit = 8,
      icon = " ",
      label = " Recent files",
    },

    -- Nord-matched footer + dynamic date
    footer = function()
      local function footer_time()
        return os.date("  %Y-%m-%d  %H:%M")
      end
      return {
        "",
        "󰀄  Xiangyu Song",
        footer_time(),
      }
    end,
  },
})

-- Nord-ish muted footer color
vim.api.nvim_set_hl(0, "DashboardFooter", {
  fg = "#6B7089",
  italic = false,
})

-- open dashboard after closing lazy (when you start nvim into :Lazy)
if vim.o.filetype == "lazy" then
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(vim.api.nvim_get_current_win()),
    once = true,
    callback = function()
      vim.schedule(function()
        vim.cmd("Dashboard")
      end)
    end,
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dashboard",
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true, nowait = true }

    -- 1. ROBUST HIDE CURSOR LOGIC ------------------------------------
    -- Get current background color. Fallback to Nord dark (#2E3440) if undefined.
    local hl = vim.api.nvim_get_hl(0, { name = "Normal" })
    local bg = hl.bg and string.format("#%06x", hl.bg) or "#2E3440"

    -- Create a highlight group that is exactly the background color
    vim.api.nvim_set_hl(0, "HiddenCursor", { fg = bg, bg = bg })

    -- Save current cursor to restore later
    local current_guicursor = vim.go.guicursor

    -- Set global cursor to a 1-pixel bar (ver1) using our invisible color
    vim.go.guicursor = "a:ver1-HiddenCursor"

    -- Restore cursor immediately when leaving the dashboard buffer
    vim.api.nvim_create_autocmd("BufLeave", {
      buffer = ev.buf,
      once = true,
      callback = function()
        vim.go.guicursor = current_guicursor
      end,
    })
    -------------------------------------------------------------------

    -- Keep it visually "fixed"
    vim.opt_local.scrolloff = 0
    vim.opt_local.sidescrolloff = 0
    vim.opt_local.wrap = false

    -- Make buffer feel like a UI
    vim.opt_local.modifiable = true
    vim.opt_local.readonly = false
    vim.opt_local.buftype = "nofile"
    vim.opt_local.bufhidden = "wipe"
    vim.opt_local.swapfile = false

    -- Hide normal editor UI
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.cursorline = false

    -- Always keep cursor at top-left
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    -- Disable movement / scrolling keys (but keep dashboard shortcuts working)
    local disable = {
      "j", "k", "h", "l",
      "<Up>", "<Down>", "<Left>", "<Right>",
      "<PageUp>", "<PageDown>", "<C-u>", "<C-d>",
      "gg", "G", "0", "$", "^",
      "<ScrollWheelUp>", "<ScrollWheelDown>",
      "<S-ScrollWheelUp>", "<S-ScrollWheelDown>",
    }

    for _, key in ipairs(disable) do
      vim.keymap.set("n", key, "<Nop>", opts)
    end

    -- If anything still moves the cursor (like resizing), snap it back
    vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
      buffer = ev.buf,
      callback = function()
        pcall(vim.api.nvim_win_set_cursor, 0, { 1, 0 })
      end,
    })
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- dashboard-nvim steals `g` (breaks gt/gT). Remove it globally.
    pcall(vim.keymap.del, "n", "g")
  end,
})