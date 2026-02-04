-- nvim/lua/plugins/blink.lua

require("blink.cmp").setup({
  keymap = {

    ["<Tab>"] = {
      function(cmp)
        -- if completion menu is visible, accept current (first by default)
        if cmp.is_visible() then
          return cmp.accept()
        end
        -- otherwise: force accept first match
        return cmp.select_and_accept({ force = true })
      end,
      "fallback",
    },

    ["<CR>"] = { "accept", "fallback" },
    ["<Esc>"] = { "cancel", "fallback" },
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
  },

  snippets = { preset = "luasnip" },

  cmdline = {
    enabled = true,
    keymap = {
      preset = "cmdline",

      ["<Down>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_next()
          end
          -- do nothing -> next action runs
        end,
        "fallback", -- lets Neovim do cmdline-history when menu isn't open
      },

      ["<Up>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_prev()
          end
        end,
        "fallback",
      },

      -- optional: also allow Ctrl-j/k or Ctrl-n/p
      ["<C-n>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },

      ["<Tab>"] = { "show", "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },

      ["<CR>"] = { "accept", "fallback" },
      ["<Esc>"] = { "cancel", "fallback" },
    },

    completion = {
      menu = { auto_show = true },
    },

    sources = function()
      local t = vim.fn.getcmdtype()
      if t == "/" or t == "?" then return { "buffer" } end
      if t == ":" then return { "cmdline", "path" } end
      return {}
    end,
  },


  completion = {
    menu = { border = "rounded" },
    documentation = { auto_show = true },
  },

  sources = { default = { "snippets", "lsp", "buffer", "path" } },
  fuzzy = {
    implementation = "lua",  -- force Lua fallback, disables warning
  },
})
