-- nvim/lua/plugins/init.lua

-- Ensure every nvim instance has a unique RPC server socket
-- AND export it to env vars that some plugins still rely on.
do
  if not vim.v.servername or vim.v.servername == "" then
    local sock = vim.fn.stdpath("run") .. "/nvim-" .. vim.fn.getpid() .. ".sock"
    pcall(vim.fn.serverstart, sock)
  end

  -- Back-compat for plugins that still read env vars instead of v:servername.
  if vim.v.servername and vim.v.servername ~= "" then
    vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
    vim.env.NVIM = vim.v.servername
  end
end

require("lazy").setup({
  ---------------------------------------------------------------------------
  -- Core deps
  ---------------------------------------------------------------------------
  { "nvim-lua/plenary.nvim", lazy = true },

  ---------------------------------------------------------------------------
  -- Theme (load first)
  ---------------------------------------------------------------------------
  {
    "shaunsingh/nord.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.nord_contrast = true
      vim.g.nord_borders = false
      vim.g.nord_disable_background = false
      vim.g.nord_cursorline_transparent = false
      vim.g.nord_enable_sidebar_background = false
      vim.g.nord_italic = false
      vim.g.nord_uniform_diff_background = true
      vim.cmd("colorscheme nord")
    end,
  },

  ---------------------------------------------------------------------------
  -- Statusline (Lualine)
  ---------------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("plugins.lualine").setup()
    end,
  },

  ---------------------------------------------------------------------------
  -- Greeter / Dashboard (keep fast)
  ---------------------------------------------------------------------------
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("plugins.dashboard")
    end,
  },

  ---------------------------------------------------------------------------
  -- Tabline / Bufferline
  ---------------------------------------------------------------------------
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("plugins.bufferline")
    end,
  },

  {
    "tiagovla/scope.nvim",
    event = "VeryLazy",
    config = true,
  },

  ---------------------------------------------------------------------------
  -- Treesitter (load when editing files)
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
      require("plugins.treesitter")
    end,
  },

  ---------------------------------------------------------------------------
  -- Git signs (load when a file buffer opens)
  ---------------------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("plugins.gitsigns")
    end,
  },

  ---------------------------------------------------------------------------
  -- Snippets (load on Insert)
  ---------------------------------------------------------------------------
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    dependencies = {
      -- optional but usually helpful; safe to keep
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("plugins.luasnip")
    end,
  },

  ---------------------------------------------------------------------------
  -- Completion (blink.cmp) - keep it, but DO NOT let it steal <Tab>
  ---------------------------------------------------------------------------
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "VeryLazy",
    dependencies = {
      { "L3MON4D3/LuaSnip", version = "v2.*" },
    },
    opts = function()
      -- IMPORTANT: your plugins/blink.lua should set <Tab>/<S-Tab> to "fallback"
      -- so LuaSnip can own them.
      return require("plugins.blink")
    end,
  },

  ---------------------------------------------------------------------------
  -- Autopairs (Insert only)
  ---------------------------------------------------------------------------
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("plugins.autopairs")
    end,
  },

  ---------------------------------------------------------------------------
  -- Telescope (on-demand: cmd + keys)
  ---------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },
      { "nvim-tree/nvim-web-devicons" },
    },
    config = function()
      require("plugins.telescope")
    end,
  },

  ---------------------------------------------------------------------------
  -- Navigation
  ---------------------------------------------------------------------------
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar" },
    config = function()
      require("grug-far").setup({})
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = { "Neotree" },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "MagicDuck/grug-far.nvim",
    },
    config = function()
      require("plugins.navigation").neotree_setup()
    end,
  },

---------------------------------------------------------------------------
-- Multi-cursor (VS Code–style)
---------------------------------------------------------------------------
  { import = "plugins.multicursor" },

  ---------------------------------------------------------------------------
  -- LSP + Mason (load when editing files)
  ---------------------------------------------------------------------------
  { "williamboman/mason.nvim", cmd = "Mason", config = true },
  { "williamboman/mason-lspconfig.nvim", event = { "BufReadPre", "BufNewFile" } },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", event = { "BufReadPre", "BufNewFile" } },

  {
    "j-hui/fidget.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = { notification = { window = { winblend = 0 } } },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "saghen/blink.cmp",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "j-hui/fidget.nvim",
    },
    config = function()
      require("plugins.lsp")
    end,
  },

  ---------------------------------------------------------------------------
  -- LaTeX
  ---------------------------------------------------------------------------
  {
    "lervag/vimtex",
    ft = { "tex" },
    init = function()
      require("plugins.vimtex")
    end,
  },

  ---------------------------------------------------------------------------
  -- Git UI (on-demand)
  ---------------------------------------------------------------------------
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
  },

  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
    config = function()
      require("neogit").setup({ integrations = { diffview = true } })
    end,
  },

  ---------------------------------------------------------------------------
  -- Debugging (DAP)
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<F9>", function() require("dap").continue() end, desc = "DAP Continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "DAP Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "DAP Step Into" },
      { "<F12>", function() require("dap").step_out() end, desc = "DAP Step Out" },
    },
    config = function()
      require("plugins.debug")
    end,
  },

  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" }, lazy = true },
  { "nvim-neotest/nvim-nio", lazy = true },

  {
    "jay-babu/mason-nvim-dap.nvim",
    ft = { "python", "r", "lua", "go" },
    dependencies = { "mason.nvim", "mfussenegger/nvim-dap" },
    config = true,
  },

  { "leoluz/nvim-dap-go", ft = { "go" }, dependencies = { "mfussenegger/nvim-dap" } },

  ---------------------------------------------------------------------------
  -- Indent guides
  ---------------------------------------------------------------------------
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("plugins.indent_line")
    end,
  },

  ---------------------------------------------------------------------------
  -- Linting / Formatting
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("plugins.lint")
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("plugins.format")
    end,
  },

  ---------------------------------------------------------------------------
  -- Slime
  ---------------------------------------------------------------------------
  {
    "jpalardy/vim-slime",
    ft = { "r", "rmd", "python", "lua", "sh", "zsh" },
    config = function()
      require("plugins.slime").setup()
    end,
  },

  ---------------------------------------------------------------------------
  -- macOS input source helper
  ---------------------------------------------------------------------------
  {
    "ivanesmantovich/xkbswitch.nvim",
    event = "VeryLazy",
    cond = function()
      return vim.fn.has("mac") == 1
    end,
  },

  ---------------------------------------------------------------------------
  -- AI plugins
  ---------------------------------------------------------------------------
  { "folke/snacks.nvim", event = "VeryLazy" },

  {
    "coder/claudecode.nvim",
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("plugins.ai").claude_setup()
    end,
  },

  {
    "gutsavgupta/nvim-gemini-companion",
    commit = "e08d1ba",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    config = function()
      require("plugins.ai").gemini_companion_setup()
    end,
  },

  ---------------------------------------------------------------------------
  -- Supermaven 
  ---------------------------------------------------------------------------
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    config = function()
      -- Your plugins/ai.lua should set accept_suggestion to something like <C-j>
      require("plugins.ai").supermaven_setup()
    end,
  },
})
