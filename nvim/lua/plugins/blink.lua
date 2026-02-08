-- nvim/lua/plugins/blink.lua

require("blink.cmp").setup({
  --------------------------------------------------------------------
  -- Keymaps
  --------------------------------------------------------------------
  keymap = {
    -- Tab should INDENT by default (and keep Neovim's snippet-jump behavior),
    -- and only interact with completion when the menu is actually visible.
    ["<Tab>"] = {
      function(cmp)
        if cmp.is_visible() then
          -- choose ONE behavior:
          -- return cmp.accept()       -- Tab accepts
          return cmp.select_next()     -- Tab cycles
        end
        -- fallback -> vim.snippet.jump if active, otherwise normal <Tab>/indent
        return nil
      end,
      "fallback",
    },

    ["<S-Tab>"] = {
      function(cmp)
        if cmp.is_visible() then
          return cmp.select_prev()
        end
        return nil
      end,
      "fallback",
    },

    ["<CR>"] = { "accept", "fallback" },
    ["<Esc>"] = { "cancel", "fallback" },

    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },

    -- Optional: keep a "force accept first match" key (so you don't lose that workflow)
    ["<C-y>"] = {
      function(cmp)
        if cmp.is_visible() then
          return cmp.accept()
        end
        return cmp.select_and_accept({ force = true })
      end,
      "fallback",
    },
  },

  --------------------------------------------------------------------
  -- Snippets
  --------------------------------------------------------------------
  snippets = { preset = "luasnip" },

  --------------------------------------------------------------------
  -- Cmdline completion
  --------------------------------------------------------------------
  cmdline = {
    enabled = true,
    keymap = {
      preset = "cmdline",

      ["<Down>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_next()
          end
          -- do nothing -> fallback handles cmdline history
        end,
        "fallback",
      },

      ["<Up>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_prev()
          end
        end,
        "fallback",
      },

      -- optional: also allow Ctrl-n/p
      ["<C-n>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },

      -- In cmdline, Tab can still show/cycle completion (this is separate from insert-mode Tab)
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
      if t == "/" or t == "?" then
        return { "buffer" }
      end
      if t == ":" then
        return { "cmdline", "path" }
      end
      return {}
    end,
  },

  --------------------------------------------------------------------
  -- Completion UI
  --------------------------------------------------------------------
  completion = {
    menu = { border = "rounded" },
    documentation = { auto_show = true },
  },

  --------------------------------------------------------------------
  -- Sources
  --------------------------------------------------------------------
  sources = {
    default = { "snippets", "lsp", "buffer", "path" },
  },

  --------------------------------------------------------------------
  -- Fuzzy matching
  --------------------------------------------------------------------
  fuzzy = {
    implementation = "lua", -- force Lua fallback, disables warning
  },
})
