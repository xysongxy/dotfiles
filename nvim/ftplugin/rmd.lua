-- nvim/ftplugin/rmd.lua

vim.opt_local.wrap = true
vim.opt_local.spell = true

-- Quick render current Rmd in a split terminal
vim.keymap.set("n", "<localleader>rr", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("split | terminal Rscript -e 'rmarkdown::render(\"" .. file .. "\")'")
end, { buffer = true, desc = "Render Rmd" })
