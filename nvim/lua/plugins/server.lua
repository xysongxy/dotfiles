-- Ensure Neovim has a unique server socket (needed by plugins that use RPC/MCP)
if vim.v.servername == nil or vim.v.servername == "" then
  local sock = vim.fn.stdpath("run") .. "/nvim-" .. vim.fn.getpid() .. ".sock"
  pcall(vim.fn.serverstart, sock)
end
