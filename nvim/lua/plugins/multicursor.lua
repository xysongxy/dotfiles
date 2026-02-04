-- nvim/lua/plugins/multicursor.lua
return {
  "mg979/vim-visual-multi",
  branch = "master",
  init = function()
    vim.g.VM_default_mappings = 0
    vim.g.VM_maps = {
      ["Find Under"]         = "<C-n>",
      ["Find Subword Under"] = "<C-n>",
      ["Select All"]         = "<C-A-n>",
      ["Skip Region"]        = "<C-x>",
      ["Remove Region"]      = "<C-p>",
      ["Add Cursor Down"]    = "<M-j>",
      ["Add Cursor Up"]      = "<M-k>",
    }
  end,
}
