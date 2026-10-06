-- nvim/lua/plugins/treesitter.lua

local treesitter = require("nvim-treesitter")

-- nvim-treesitter's main branch uses the new, incompatible API. Parsers and
-- queries are installed under stdpath("data")/site by default.
treesitter.setup({})

local ensure_installed = { "c", "lua", "latex", "python", "vim", "r", "markdown" }
local installed = treesitter.get_installed("parsers")
local missing = vim.tbl_filter(function(parser)
  return not vim.list_contains(installed, parser)
end, ensure_installed)

if #missing > 0 then
  treesitter.install(missing)
end

-- Treat RMarkdown as markdown Treesitter input.
vim.treesitter.language.register("markdown", "rmd")

local parser_by_filetype = {
  c = "c",
  lua = "lua",
  markdown = "markdown",
  python = "python",
  r = "r",
  rmd = "markdown",
  tex = "latex",
  vim = "vim",
}

local group = vim.api.nvim_create_augroup("TreesitterFeatures", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = vim.tbl_keys(parser_by_filetype),
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > 100 * 1024 then
      return
    end

    local parser = parser_by_filetype[vim.bo[args.buf].filetype]
    if not pcall(vim.treesitter.start, args.buf, parser) then
      return
    end

    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
