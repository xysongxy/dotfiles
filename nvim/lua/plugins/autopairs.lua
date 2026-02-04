-- nvim/lua/plugins/autopairs.lua

local npairs = require("nvim-autopairs")
local Rule = require("nvim-autopairs.rule")

npairs.setup({
  check_ts = false,
  -- Optional: map <C-h> to delete the pair if you backspace
  map_bs = true, 
  map_c_h = true,
  map_c_w = true,
})

-- Explicitly add rules for LaTeX to force them to work in math mode
npairs.add_rules({
  Rule("(", ")", "tex"),
  Rule("[", "]", "tex"),
  Rule("{", "}", "tex"),
  -- Ensure $ pairs with $ in tex files
  Rule("$", "$", "tex"),
})