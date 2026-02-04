-- nvim/lua/core/keymaps.lua

local map = vim.keymap.set

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function safe_cmd(cmd)
  return function()
    local ok = pcall(vim.cmd, cmd)
    if not ok then
      vim.notify("Command not found: " .. cmd, vim.log.levels.WARN)
    end
  end
end

---------------------------------------------------------------------
-- Basic
---------------------------------------------------------------------
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit all (force)" })

map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "No highlight" })

---------------------------------------------------------------------
-- Navigation / Windows
---------------------------------------------------------------------
map("n", "<C-h>", "<C-w>h", { desc = "Go left" })
map("n", "<C-j>", "<C-w>j", { desc = "Go down" })
map("n", "<C-k>", "<C-w>k", { desc = "Go up" })
map("n", "<C-l>", "<C-w>l", { desc = "Go right" })

map("n", "<A-Left>",  "<cmd>vertical resize -2<cr>", { desc = "Resize left" })
map("n", "<A-Right>", "<cmd>vertical resize +2<cr>", { desc = "Resize right" })
map("n", "<A-Up>",    "<cmd>resize +2<cr>",          { desc = "Resize up" })
map("n", "<A-Down>",  "<cmd>resize -2<cr>",          { desc = "Resize down" })

-- Better wrapped-line movement
map("n", "j", "gj", { silent = true })
map("n", "k", "gk", { silent = true })

---------------------------------------------------------------------
-- Terminal
---------------------------------------------------------------------
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- mars.nvim style: jk escape in insert + terminal
map({ "i", "t" }, "jk", "<Esc>", { desc = "Escape", noremap = true, silent = true })

-- mars.nvim style: ; -> :
map("n", ";", ":", { desc = "Command mode", noremap = true })

---------------------------------------------------------------------
-- File Explorer / Search
---------------------------------------------------------------------
map("n", "<C-e>", "<cmd>Neotree toggle<cr>", { desc = "Explorer (neo-tree)", silent = true })
map("n", "<leader>gs", "<cmd>GrugFar<cr>", { desc = "Find/Replace (grug-far)", silent = true })

---------------------------------------------------------------------
-- Leap
---------------------------------------------------------------------
map({ "n", "x", "o" }, "e", "<Plug>(leap-forward)", { desc = "Leap forward" })
map({ "n", "x", "o" }, "E", "<Plug>(leap-cross-window)", { desc = "Leap cross-window" })

---------------------------------------------------------------------
-- Git
---------------------------------------------------------------------
map("n", "<leader>ng", "<cmd>Neogit<cr>", { desc = "Neogit", silent = true })

---------------------------------------------------------------------
-- Dashboard
---------------------------------------------------------------------
map("n", "<leader>g", "<Cmd>Dashboard<CR>", { desc = "Open dashboard" })

---------------------------------------------------------------------
-- Bufferline keymaps
---------------------------------------------------------------------
local map = vim.keymap.set

map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close others" })

for i = 1, 9 do
  map("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<cr>", { desc = "Go to buffer " .. i })
end

map("n", "<C-t>", function()
  local builtin = require("telescope.builtin")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  builtin.find_files({
    attach_mappings = function(prompt_bufnr, map2)
      local function open_file()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry and entry.path then
          vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
        end
      end

      map2("i", "<CR>", open_file)
      map2("n", "<CR>", open_file)
      return true
    end,
  })
end, { desc = "Open file (Telescope)", silent = true })

---------------------------------------------------------------------
-- Close buffer (tab-local) but tab NEVER disappears
---------------------------------------------------------------------
map("n", "<leader>bd", function()
  _G.tab_safe_bdelete()
end, { desc = "Close buffer (tab stays; scratch if last)" })

vim.api.nvim_create_user_command("BD", function()
  _G.tab_safe_bdelete()
end, { desc = "Close buffer (tab stays; scratch if last)" })

---------------------------------------------------------------------
-- Tabs: new tab opens Dashboard
---------------------------------------------------------------------
local function open_dashboard()
  -- dashboard-nvim command
  if pcall(vim.cmd, "Dashboard") then return end
  -- fallback: if you ever switch dashboard plugin
  if pcall(vim.cmd, "Alpha") then return end
  -- final fallback
  vim.cmd("enew")
end

map("n", "<leader>tn", function()
  vim.cmd("tabnew")
  open_dashboard()
end, { desc = "New tab (dashboard)", silent = true })

map("n", "<leader>tl", "<cmd>tabnext<cr>", { desc = "Next tab", silent = true })
map("n", "<leader>th", "<cmd>tabprevious<cr>", { desc = "Prev tab", silent = true })
map("n", "<leader>tc", "<cmd>tabclose<cr>", { desc = "Close tab", silent = true })

---------------------------------------------------------------------
-- Mouse (for closing Neovim tabs from tabline)
---------------------------------------------------------------------
vim.o.mouse = "a"
vim.o.showtabline = 2

---------------------------------------------------------------------
-- Slime (send)
-- Avoid conflict with Claude selection key (<leader>cs). Use <leader>ss
---------------------------------------------------------------------
map("n", "<leader>ss", "<Plug>SlimeSendCell", { desc = "Slime send cell", silent = true })
map("x", "<leader>ss", "<Plug>SlimeRegionSend", { desc = "Slime send selection", silent = true })

---------------------------------------------------------------------
-- DAP
---------------------------------------------------------------------
map("n", "<F5>", function() require("dap").continue() end, { desc = "Debug: Start/Continue" })
map("n", "<F1>", function() require("dap").step_into() end, { desc = "Debug: Step Into" })
map("n", "<F2>", function() require("dap").step_over() end, { desc = "Debug: Step Over" })
map("n", "<F3>", function() require("dap").step_out() end, { desc = "Debug: Step Out" })

map("n", "<leader>b", function() require("dap").toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })
map("n", "<leader>B", function()
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Set Conditional Breakpoint" })

map("n", "<F7>", function() require("dapui").toggle() end, { desc = "Debug: Toggle UI" })

---------------------------------------------------------------------
-- AI (safe wrappers so keymaps don't break when plugin not loaded)
-- NOTE: keep these here; you also set keys inside plugins/ai.lua, but
-- that is fine. If you prefer ONE source of truth, remove in ai.lua.
---------------------------------------------------------------------
-- Claude
map("n", "<leader>cc", safe_cmd("ClaudeCode"), { desc = "Claude: Toggle" })
map("n", "<leader>cf", safe_cmd("ClaudeCodeFocus"), { desc = "Claude: Focus" })
map("n", "<leader>cr", safe_cmd("ClaudeCode --resume"), { desc = "Claude: Resume" })
map("n", "<leader>cC", safe_cmd("ClaudeCode --continue"), { desc = "Claude: Continue" })
map("n", "<leader>cm", safe_cmd("ClaudeCodeSelectModel"), { desc = "Claude: Select model" })
map("n", "<leader>cb", safe_cmd("ClaudeCodeAdd %"), { desc = "Claude: Add current buffer" })
map("x", "<leader>cs", safe_cmd("ClaudeCodeSend"), { desc = "Claude: Send selection" })
map("n", "<leader>cA", safe_cmd("ClaudeCodeDiffAccept"), { desc = "Claude: Accept diff" })
map("n", "<leader>cD", safe_cmd("ClaudeCodeDiffDeny"), { desc = "Claude: Deny diff" })

-- Gemini (adjust command names if your plugin exposes different ones)
map("n", "<leader>gg", safe_cmd("GeminiToggle"), { desc = "Gemini: Toggle" })
map("n", "<leader>gc", safe_cmd("GeminiSwitchToCli"), { desc = "Gemini: Switch to CLI" })
map("x", "<leader>gS", safe_cmd("GeminiSend"), { desc = "Gemini: Send selection" })
map("n", "<leader>ga", safe_cmd("GeminiAccept"), { desc = "Gemini: Accept diff" })
map("n", "<leader>gd", safe_cmd("GeminiReject"), { desc = "Gemini: Reject diff" })
