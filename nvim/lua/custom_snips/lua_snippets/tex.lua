local ls = require("luasnip")
local s, t, i = ls.snippet, ls.text_node, ls.insert_node

local function in_mathzone()
  local ok, math = pcall(vim.fn["vimtex#syntax#in_mathzone"])
  return ok and math == 1
end

return {
  s({
    trig = [[\text]],
    name = "Text in math",
    snippetType = "autosnippet",
    wordTrig = false,
    condition = in_mathzone,
  }, {
    t([[\text{]]),
    i(1),
    t("}"),
    i(0),
  }),
}
