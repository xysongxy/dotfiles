-- nvim/lua/plugins/luasnip.lua
local luasnip = require("luasnip")

luasnip.config.set_config({
  history = true,
  updateevents = "TextChanged,TextChangedI",
  enable_autosnippets = true,
})

-- Load snippets
-- pcall(function()
--   require("luasnip.loaders.from_vscode").lazy_load()
-- end)

local config = vim.fn.stdpath("config")
pcall(function()
  require("luasnip.loaders.from_vscode").lazy_load({
    paths = { config .. "/lua/custom_snips/vs_snippets" },
  })
end)

pcall(function()
  require("luasnip.loaders.from_lua").lazy_load({
    paths = { config .. "/lua/custom_snips/lua_snippets" },
  })
end)

-- ✅ Make .Rmd (ft=rmd) use markdown snippets
luasnip.filetype_extend("rmd", { "rmarkdown" })

-- ✅ Snippet jumping keys (do not fight blink's <Tab>)
vim.keymap.set({ "i", "s" }, "<C-j>", function()
  if luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
  end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-k>", function()
  if luasnip.jumpable(-1) then
    luasnip.jump(-1)
  end
end, { silent = true })
