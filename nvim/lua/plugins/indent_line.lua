-- lua/plugins/indent_line.lua
require("ibl").setup({
  enabled = true,

  exclude = {
    filetypes = {
      "dashboard",
      "alpha",
      "starter",
      "snacks_dashboard",
      "lazy",
      "help",
      "terminal",
    },
    buftypes = {
      "terminal",
      "nofile",
    },
  },
})
