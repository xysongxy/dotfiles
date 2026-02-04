-- nvim/lua/plugins/gitsigns.lua

require("gitsigns").setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },

  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Jump between hunks, but respect :diff mode
    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end, { desc = "Jump to next git change" })

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end, { desc = "Jump to previous git change" })

    -- Stage/reset hunks (visual + normal)
    map("v", "<leader>hs", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { desc = "git stage hunk" })

    map("v", "<leader>hr", function()
      gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { desc = "git reset hunk" })

    map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "git stage hunk" })
    map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "git reset hunk" })
    map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "git stage buffer" })

    -- NOTE: his config says "undo stage hunk" but calls stage_hunk.
    -- Correct is undo_stage_hunk.
    map("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "git undo stage hunk" })

    map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "git reset buffer" })
    map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "git preview hunk" })
    map("n", "<leader>hb", gitsigns.blame_line, { desc = "git blame line" })
    map("n", "<leader>hd", gitsigns.diffthis, { desc = "git diff against index" })

    map("n", "<leader>hD", function()
      gitsigns.diffthis("@")
    end, { desc = "git diff against last commit" })

    map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "Toggle line blame" })
    map("n", "<leader>tD", gitsigns.preview_hunk_inline, { desc = "Toggle deleted (inline preview)" })
  end,
})
