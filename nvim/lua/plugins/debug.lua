-- nvim/lua/plugins/debug.lua

local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  return
end

local ok_ui, dapui = pcall(require, "dapui")
if not ok_ui then
  return
end

pcall(function()
  require("mason-nvim-dap").setup({
    automatic_installation = false,
    ensure_installed = {}, 
  })
end)

dapui.setup({
  icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
  controls = {
    icons = {
      pause = "⏸",
      play = "▶",
      step_into = "⏎",
      step_over = "⏭",
      step_out = "⏮",
      step_back = "b",
      run_last = "▶▶",
      terminate = "⏹",
      disconnect = "⏏",
    },
  },
})

dap.listeners.after.event_initialized["dapui_config"] = dapui.open
dap.listeners.before.event_terminated["dapui_config"] = dapui.close
dap.listeners.before.event_exited["dapui_config"] = dapui.close

pcall(function()
  require("dap-go").setup({
    delve = { detached = vim.fn.has("win32") == 0 },
  })
end)
