-- nvim/lua/plugins/navigation.lua

local M = {}

-- Helper: open / reuse a named grug-far instance with prefills
local function open_grug_far(prefills)
  local grug_far = require("grug-far")

  if not grug_far.has_instance("explorer") then
    grug_far.open({ instanceName = "explorer", prefills = prefills })
  else
    local inst = grug_far.get_instance("explorer")
    inst:open()
    inst:update_input_values(prefills, false)
  end
end

function M.neotree_setup()
  require("neo-tree").setup({
    commands = {
      grug_far_replace = function(state)
        local node = state.tree:get_node()
        local prefills = {
          paths = node.type == "directory"
              and vim.fn.fnameescape(vim.fn.fnamemodify(node:get_id(), ":p"))
            or vim.fn.fnameescape(vim.fn.fnamemodify(node:get_id(), ":h")),
        }
        open_grug_far(prefills)
      end,

      grug_far_replace_visual = function(_, selected_nodes, _)
        local paths = {}
        for _, node in pairs(selected_nodes) do
          local path = node.type == "directory"
              and vim.fn.fnameescape(vim.fn.fnamemodify(node:get_id(), ":p"))
            or vim.fn.fnameescape(vim.fn.fnamemodify(node:get_id(), ":h"))
          table.insert(paths, path)
        end
        open_grug_far({ paths = table.concat(paths, "\n") })
      end,
    },

    filesystem = {
      window = {
        mappings = {
          ["<C-e>"] = "close_window",
          ["o"] = "open",
          ["O"] = {
            "show_help",
            nowait = false,
            config = { title = "Order by", prefix_key = "O" },
          },
          ["Oc"] = { "order_by_created", nowait = false },
          ["Od"] = { "order_by_diagnostics", nowait = false },
          ["Og"] = { "order_by_git_status", nowait = false },
          ["Om"] = { "order_by_modified", nowait = false },
          ["On"] = { "order_by_name", nowait = false },
          ["Os"] = { "order_by_size", nowait = false },
          ["Ot"] = { "order_by_type", nowait = false },
          ["<CR>"] = "open",
          ["S"] = "open_split",      -- horizontal split
          ["V"] = "open_vsplit",     -- vertical split
          ["T"] = "open_tabnew",     -- real Vim tab (rare)
        },
      },
    },

    window = {
      mappings = {
        z = "grug_far_replace",
        -- Optional: if you want a key for multi-select replace
        -- Z = "grug_far_replace_visual",
      },
    },

    event_handlers = {
      {
        event = "file_open_requested",
        handler = function()
          require("neo-tree.command").execute({ action = "close" })
        end,
      },
    },
  })
end

return M
