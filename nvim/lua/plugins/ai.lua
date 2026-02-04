-- nvim/lua/plugins/ai.lua
local M = {}

-----------------------------------------------------------------------
-- helpers
-----------------------------------------------------------------------
local function prequire(mod)
  local ok, m = pcall(require, mod)
  if ok then return m end
  return nil
end

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

local function ensure_server_and_env()
  if not vim.v.servername or vim.v.servername == "" then
    local sock = vim.fn.stdpath("run") .. "/nvim-" .. vim.fn.getpid() .. ".sock"
    pcall(vim.fn.serverstart, sock)
  end
  if vim.v.servername and vim.v.servername ~= "" then
    vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
    vim.env.NVIM = vim.v.servername
  end
end

-----------------------------------------------------------------------
-- Claude Code (coder/claudecode.nvim)
-----------------------------------------------------------------------
function M.claude_setup()
  local claudecode = prequire("claudecode")
  if not claudecode then
    vim.notify("claudecode.nvim not found", vim.log.levels.ERROR)
    return
  end

  if type(claudecode.setup) == "function" then
    claudecode.setup({})
  end

  map("n", "<leader>cc", "<cmd>ClaudeCode<cr>", "Claude: Toggle")
  map("n", "<leader>cf", "<cmd>ClaudeCodeFocus<cr>", "Claude: Focus")
  map("n", "<leader>cr", "<cmd>ClaudeCode --resume<cr>", "Claude: Resume")
  map("n", "<leader>cC", "<cmd>ClaudeCode --continue<cr>", "Claude: Continue")
  map("n", "<leader>cm", "<cmd>ClaudeCodeSelectModel<cr>", "Claude: Select model")
  map("n", "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", "Claude: Add buffer")
  map("x", "<leader>cs", "<cmd>ClaudeCodeSend<cr>", "Claude: Send selection")
  map("n", "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>", "Claude: Accept diff")
  map("n", "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>", "Claude: Deny diff")
end

-----------------------------------------------------------------------
-- Gemini Companion (gutsavgupta/nvim-gemini-companion)
-----------------------------------------------------------------------
function M.gemini_companion_setup()
  local gemini = prequire("gemini")
  if not gemini then
    vim.notify("nvim-gemini-companion not found", vim.log.levels.ERROR)
    return
  end

  -- Ensure server exists
  if not vim.v.servername or vim.v.servername == "" then
    local sock = vim.fn.stdpath("run") .. "/nvim-" .. vim.fn.getpid() .. ".sock"
    pcall(vim.fn.serverstart, sock)
  end

  -- IMPORTANT: Some versions of gemini-companion read env vars (not v:servername).
  -- Force them to be set for every instance.
  vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
  vim.env.NVIM = vim.v.servername

  local ok, err = pcall(gemini.setup, {
    mcp = {
      enabled = true,
      -- also provide sockname in case this version supports it
      sockname = vim.v.servername,
    },
  })

  if not ok then
    vim.notify("Gemini setup failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  map("n", "<leader>gg", "<cmd>GeminiToggle<cr>", "Gemini: Toggle sidebar")
  map("n", "<leader>gc", "<cmd>GeminiSwitchToCli<cr>", "Gemini: Switch to CLI")
  map("x", "<leader>gS", "<cmd>GeminiSend<cr>", "Gemini: Send selection")
  map("n", "<leader>ga", "<cmd>GeminiAccept<cr>", "Gemini: Accept diff")
  map("n", "<leader>gd", "<cmd>GeminiReject<cr>", "Gemini: Reject diff")
end
-----------------------------------------------------------------------
-- Supermaven (supermaven-inc/supermaven-nvim)
-----------------------------------------------------------------------
function M.supermaven_setup()
  local sm = prequire("supermaven-nvim")
  if not sm then
    vim.notify("supermaven-nvim not found", vim.log.levels.ERROR)
    return
  end

  sm.setup({
    keymaps = {
      -- Accept FULL suggestion
      accept_suggestion = "<D-Enter>",  -- Cmd + Enter

      -- Accept NEXT WORD
      accept_word = "<C-E>",  -- Cmd + →

      -- Optional but recommended
      clear_suggestion = "<C-]>",
    },
  })

  -- (optional) quick toggle
  map("n", "<leader>sm", "<cmd>SupermavenToggle<cr>", "Supermaven: Toggle")
end

return M
