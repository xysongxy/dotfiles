-- nvim/lua/plugins/format.lua
require("conform").setup({
  formatters_by_ft = {
    python = { "ruff_format" },
  },
})

vim.keymap.set("n", "<leader>f", function()
  require("conform").format({ lsp_fallback = true })
end, { desc = "Format buffer" })
