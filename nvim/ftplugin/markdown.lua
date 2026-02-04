-- nvim/ftplugin/markdown.lua

vim.opt_local.wrap = true
vim.opt_local.spell = true
vim.opt_local.conceallevel = 2


-- Modification dates
vim.api.nvim_create_autocmd({ "BufWritePre", "FileWritePre" }, {
  buffer = bufnr,
  callback = function()
    local last_line = math.min(20, vim.fn.line("$"))
    for i = 1, last_line do
      local line = vim.fn.getline(i)
      if line:match("^modified:") then
        vim.fn.setline(i, "modified: " .. os.date("%Y-%m-%d %H:%M:%S"))
        break
      end
    end
  end,
})