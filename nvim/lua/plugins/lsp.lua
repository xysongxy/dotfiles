-- nvim/lua/plugins/lsp.lua
-- Your Neovim 0.11+ style, with mars.nvim/kickstart-style LspAttach behaviors.

-- -----------------------------
-- Mason: ensure servers installed
-- -----------------------------
pcall(function()
  require("mason-lspconfig").setup({
    ensure_installed = { "pyright", "r_language_server", "texlab", "marksman" },
  })
end)

-- Optional: auto-install extra tools (only if you installed mason-tool-installer.nvim)
pcall(function()
  require("mason-tool-installer").setup({
    ensure_installed = {
      -- formatters / linters you likely want
      "stylua",
      "markdownlint",
    },
  })
end)

-- -----------------------------
-- Diagnostics UI (his style)
-- -----------------------------
vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  } or {},
  virtual_text = {
    source = "if_many",
    spacing = 2,
    format = function(d)
      return d.message
    end,
  },
})

-- -----------------------------
-- LspAttach: buffer-local keymaps + extra behaviors
-- -----------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(event)
    -- Transparent floats (matches his)
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "DiagnosticFloating", { bg = "none" })

    local bufnr = event.buf
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    -- Keep your VS Code-like basics (buffer-local now)
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gr", vim.lsp.buf.references, "References")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>dd", vim.diagnostic.open_float, "Diagnostics (float)")

    -- Add his telescope-powered “gr*” set (doesn't conflict with your gd/gr/K)
    local ok_tb, tb = pcall(require, "telescope.builtin")
    if ok_tb then
      map("n", "grr", tb.lsp_references, "LSP: References (Telescope)")
      map("n", "gri", tb.lsp_implementations, "LSP: Implementations (Telescope)")
      map("n", "grd", tb.lsp_definitions, "LSP: Definitions (Telescope)")
      map("n", "gO", tb.lsp_document_symbols, "LSP: Document symbols")
      map("n", "gW", tb.lsp_dynamic_workspace_symbols, "LSP: Workspace symbols")
      map("n", "grt", tb.lsp_type_definitions, "LSP: Type definitions")
    end

    -- His "L" = line diagnostics float
    map("n", "gl", function()
      vim.diagnostic.open_float(0, { scope = "line" })
    end, "Diagnostics (line float)")

    -- Yank diagnostics with file:line:col (his helper)
    map("n", "<leader>yd", function()
      local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1
      local diags = vim.diagnostic.get(bufnr, { lnum = line_num })

      if #diags == 0 then
        vim.notify("No diagnostics on this line")
        return
      end

      local file_path = vim.api.nvim_buf_get_name(bufnr)
      local yank_text = ""

      for _, d in ipairs(diags) do
        local formatted = string.format("%s:%d:%d: %s", file_path, d.lnum + 1, d.col + 1, d.message)
        yank_text = yank_text .. formatted .. "\n"
      end

      vim.fn.setreg("+", yank_text)
      vim.notify("Yanked diagnostic with location!")
    end, "Yank diagnostics (file:line:col)")

    -- Document highlight (his)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, bufnr) then
      local hl_group = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })

      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = hl_group,
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = hl_group,
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
        callback = function(e2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = e2.buf })
        end,
      })
    end

    -- Inlay hints toggle (his)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, bufnr) then
      map("n", "<leader>th", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
      end, "Toggle inlay hints")
    end
  end,
})

-- -----------------------------
-- Capabilities (Blink) + 0.11 config API
-- -----------------------------
local defaults = {}

pcall(function()
  defaults.capabilities = require("blink.cmp").get_lsp_capabilities()
end)
-- -----------------------------
-- Capabilities (Blink) + 0.11 config API (merge, don't overwrite!)
-- -----------------------------
local caps = vim.lsp.protocol.make_client_capabilities()
pcall(function()
  caps = require("blink.cmp").get_lsp_capabilities(caps)
end)

local function merge(server, extra)
  local base = vim.lsp.config[server]
  if not base then
    vim.notify(("LSP server config not found: %s"):format(server), vim.log.levels.WARN)
    return
  end
  vim.lsp.config[server] = vim.tbl_deep_extend("force", base, extra or {})
end

merge("pyright", { capabilities = caps })
merge("r_language_server", { capabilities = caps })
merge("texlab", { capabilities = caps })
merge("marksman", { capabilities = caps })

vim.lsp.enable({ "pyright", "r_language_server", "texlab", "marksman" })
