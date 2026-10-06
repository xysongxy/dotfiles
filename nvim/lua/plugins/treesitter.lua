-- nvim/lua/plugins/treesitter.lua

local ok, configs = pcall(require, "nvim-treesitter.configs")
if not ok then
  return
end

configs.setup({
  ensure_installed = { "c", "lua", "latex", "python", "vim", "r", "markdown" },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
    disable = function(_, buf)
      local ok2, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      return ok2 and stats and stats.size > 100 * 1024
    end,
  },
  indent = { enable = true },
})

-- Treat RMarkdown as markdown treesitter parser
pcall(function()
  vim.treesitter.language.register("markdown", "rmd")
end)
