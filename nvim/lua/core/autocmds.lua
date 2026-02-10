-- nvim/lua/core/autocmds.lua
local aug = vim.api.nvim_create_augroup
local au  = vim.api.nvim_create_autocmd

---------------------------------------------------------------------
-- Yank highlight
---------------------------------------------------------------------
au("TextYankPost", {
  group = aug("YankHighlight", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})

---------------------------------------------------------------------
-- Trim trailing whitespace (safe files only)
---------------------------------------------------------------------
au("BufWritePre", {
  group = aug("TrimWhitespace", { clear = true }),
  pattern = { "*.lua", "*.py", "*.c", "*.cpp", "*.h", "*.R", "*.r" },
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

---------------------------------------------------------------------
-- Read-only dashboards
---------------------------------------------------------------------
au("FileType", {
  group = aug("ReadonlyDashboards", { clear = true }),
  pattern = { "dashboard", "alpha", "starter" },
  callback = function()
    vim.opt_local.modified = false
    vim.opt_local.modifiable = true
    vim.opt_local.readonly = false
  end,
})

---------------------------------------------------------------------
-- Tab-local buffer bookkeeping + Dashboard Protection
---------------------------------------------------------------------
do
  local group = aug("TabLocalBuffersAndDashboard", { clear = true })

  local function is_dashboard(bufnr)
    return vim.bo[bufnr].filetype == "dashboard"
  end

  local function ensure_in_tab_bufs(bufnr)
    if type(vim.t.bufs) ~= "table" then
      vim.t.bufs = {}
    end
    if not vim.tbl_contains(vim.t.bufs, bufnr) then
      local bufs = vim.t.bufs
      table.insert(bufs, bufnr)
      vim.t.bufs = bufs
    end
  end

  local function is_real_file_buffer(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return false end
    if not vim.bo[bufnr].buflisted then return false end
    if vim.bo[bufnr].buftype ~= "" then return false end
    local name = vim.api.nvim_buf_get_name(bufnr) or ""
    if name == "" then return false end
    local ft = vim.bo[bufnr].filetype
    if ft == "neo-tree" or ft == "lazy" or ft == "dashboard" then return false end
    return true
  end

  -- 1) Register dashboard to tab
  au("FileType", {
    group = group,
    pattern = "dashboard",
    callback = function(ev)
      vim.bo[ev.buf].buflisted = true
      ensure_in_tab_bufs(ev.buf)
    end,
  })

  -- 2) Register buffers & track history
  au("BufEnter", {
    group = group,
    callback = function(ev)
      local b = ev.buf
      if not vim.api.nvim_buf_is_valid(b) then return end
      if vim.bo[b].buflisted then
        ensure_in_tab_bufs(b)
      end
      if is_real_file_buffer(b) then
        vim.t.last_real_buf = b
      end
    end,
  })

  -- 3) Tab switch: jump away from dashboard if possible
  au("TabEnter", {
    group = group,
    callback = function()
      local cur = vim.api.nvim_get_current_buf()
      if not is_dashboard(cur) then return end
      local last = vim.t.last_real_buf
      if last and vim.api.nvim_buf_is_valid(last) then
        vim.schedule(function()
          if is_dashboard(vim.api.nvim_get_current_buf()) then
            pcall(vim.api.nvim_set_current_buf, last)
          end
        end)
      end
    end,
  })

  -- 4) SAFE: After opening a real file from dashboard, wipe the dashboard buffer
  au("BufEnter", {
    group = group,
    callback = function(ev)
      local cur = ev.buf
      if not is_real_file_buffer(cur) then return end

      local prev = vim.fn.bufnr("#")
      if prev > 0 and vim.api.nvim_buf_is_valid(prev) and is_dashboard(prev) then
        vim.schedule(function()
          pcall(vim.api.nvim_buf_delete, prev, { force = true })
        end)
      end
    end,
  })
end

---------------------------------------------------------------------
-- Return to dashboard ONLY when truly nothing is left anywhere
-- (Do NOT fight your tab-local behavior)
---------------------------------------------------------------------
au("BufDelete", {
  group = aug("ReturnToDashboard", { clear = true }),
  callback = function()
    vim.schedule(function()
      -- If any real file buffers exist, do nothing.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf)
          and vim.api.nvim_buf_is_loaded(buf)
          and vim.bo[buf].buflisted
          and vim.bo[buf].buftype == ""
          and (vim.api.nvim_buf_get_name(buf) or "") ~= "" then
          return
        end
      end

      -- Otherwise, show dashboard (only if we're not already on it)
      if vim.bo.filetype ~= "dashboard" then
        pcall(vim.cmd, "Dashboard")
      end
    end)
  end,
})

---------------------------------------------------------------------
-- R / Rmd convenience insertions
--   - ⌘⇧M : insert %>%  (pipe)
--   - ⌥-  : insert <-   (assignment)
---------------------------------------------------------------------
au("FileType", {
  group = aug("RInsertHelpers", { clear = true }),
  pattern = { "r", "rmd", "rmarkdown", "quarto" },
  callback = function(ev)
    local function bmap(modes, lhs, rhs, desc)
      vim.keymap.set(modes, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
    end

    local function insert_text(txt)
      if vim.fn.mode():match("i") then
        vim.api.nvim_put({ txt }, "c", true, true)
      else
        vim.api.nvim_put({ txt }, "c", true, true)
      end
    end

    -- ⌘⇧M → %>% (pipe)
    bmap({ "i", "n" }, "<D-M>", function()
      insert_text(" %>% ")
    end, "R: insert %>% pipe")

    -- ⌥- → <- (assignment)
    bmap({ "i", "n" }, "<M-->", function()
      insert_text(" <- ")
    end, "R: insert <- assignment")
  end,
})

---------------------------------------------------------------------
-- R / Rmd / Quarto: indentation defaults (RStudio-ish)
---------------------------------------------------------------------
au("FileType", {
  group = aug("RIndentDefaults", { clear = true }),
  pattern = { "r", "rmd", "rmarkdown", "quarto" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.autoindent = true

    -- keep your existing tweak
    vim.opt_local.cinoptions:append("(0")
  end,
})

---------------------------------------------------------------------
-- R / Rmd: RStudio-like Enter inside (), {}, []
-- Goals:
--   1) lm(|)   -> lm(\n    |\n)
--   2) lm(x|)  -> lm(x\n    |\n)          (when autopairs already inserted the close)
--   3) Inside an open pair and you end a line with + , %>% |> etc:
--        \n    |  (continuation indent)
-- Default Enter must behave like normal (no "jump 2 lines").
---------------------------------------------------------------------
au("FileType", {
  group = aug("RSmartEnter", { clear = true }),
  pattern = { "r", "rmd", "rmarkdown", "quarto" },
  callback = function(ev)
    local PAIRS = {
      ["("] = ")",
      ["{"] = "}",
      ["["] = "]",
    }
    local CLOSE_TO_OPEN = {
      [")"] = "(",
      ["}"] = "{",
      ["]"] = "[",
    }

    local function r_line_continues(before)
      local s = (before:gsub("%s+$", ""))
      if s == "" then return false end
      if s:match("%+$") then return true end
      if s:match(",%s*$") then return true end
      if s:match("%%>%%%s*$") then return true end
      if s:match("|>%s*$") then return true end
      return false
    end

    local function count_char(str, pat)
      return select(2, str:gsub(pat, ""))
    end

    local function has_unmatched_open(before, open_ch)
      local close_ch = PAIRS[open_ch]
      if not close_ch then return false end
      local opens = count_char(before, "%" .. open_ch)
      local closes = count_char(before, "%" .. close_ch)
      return opens > closes
    end

    local function any_unmatched_open(before)
      for open_ch, _ in pairs(PAIRS) do
        if has_unmatched_open(before, open_ch) then
          return true
        end
      end
      return false
    end

    local function first_close_char(after)
      -- first non-space char, if it's a close delimiter we care about
      local c = after:match("^%s*([%)%}%]])")
      return c
    end

    vim.keymap.set("i", "<CR>", function()
      local bufnr = ev.buf
      local row, col0 = unpack(vim.api.nvim_win_get_cursor(0)) -- row 1-based, col 0-based
      local line = vim.api.nvim_get_current_line()

      local before = line:sub(1, col0)
      local after  = line:sub(col0 + 1)

      local base_ws = line:match("^(%s*)") or ""
      local sw = vim.bo[bufnr].shiftwidth
      if not sw or sw <= 0 then sw = 4 end
      local inner_ws = base_ws .. string.rep(" ", sw)

      local last_before = before:sub(-1)
      local close_after = first_close_char(after)

      -- Case 1: exactly between matching pair: (|) / {|} / [|]
      if PAIRS[last_before] and close_after == PAIRS[last_before] then
        vim.api.nvim_buf_set_text(
          bufnr,
          row - 1, col0,
          row - 1, col0,
          { "", inner_ws, base_ws }
        )
        vim.api.nvim_win_set_cursor(0, { row + 1, #inner_ws })
        return
      end

      -- Case 2: inside a pair and cursor is right before a closing delimiter
      -- e.g. lm(x|) where after begins with ")"
      if close_after and any_unmatched_open(before) then
        local open_needed = CLOSE_TO_OPEN[close_after]
        if open_needed and has_unmatched_open(before, open_needed) then
          vim.api.nvim_buf_set_text(
            bufnr,
            row - 1, col0,
            row - 1, col0,
            { "", inner_ws, base_ws }
          )
          vim.api.nvim_win_set_cursor(0, { row + 1, #inner_ws })
          return
        end
      end

      -- Case 3: continuation inside any open pair (+, , , %>% , |> at end of "before")
      if r_line_continues(before) and any_unmatched_open(before) then
        vim.api.nvim_buf_set_text(
          bufnr,
          row - 1, col0,
          row - 1, col0,
          { "", inner_ws }
        )
        vim.api.nvim_win_set_cursor(0, { row + 1, #inner_ws })
        return
      end

      -- Default: real newline (no double-jump)
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<CR>", true, false, true),
        "in",
        false
      )
    end, { buffer = ev.buf, silent = true, desc = "R: RStudio-like Enter for (), {}, []" })
  end,
})

---------------------------------------------------------------------
-- R / RMarkdown / Quarto
-- Goal:
--   - ⌥Enter sends each *logical expression* in the current chunk
--     using bracketed paste (so it does NOT execute line-by-line)
--   - Disable Cmd+Enter in INSERT (safety: if anything else mapped it)
---------------------------------------------------------------------
au("FileType", {
  group = aug("RKeymaps", { clear = true }),
  pattern = { "r", "rmd", "rmarkdown", "quarto" },
  callback = function(ev)
    local function bmap(modes, lhs, rhs, desc)
      vim.keymap.set(modes, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
    end

    -- If some other plugin mapped Cmd+Enter in insert, remove it for these buffers.
    pcall(vim.keymap.del, "i", "<D-CR>", { buffer = ev.buf })

    -----------------------------------------------------------------
    -- helpers for parsing expressions
    -----------------------------------------------------------------
    local function is_blank(line)
      return line:match("^%s*$") ~= nil
    end

    local function strip_strings_and_comments(line)
      line = line:gsub("#.*$", "")
      line = line:gsub([["([^"\\]|\\.)*"]], [[""]])
      line = line:gsub([['([^'\\]|\\.)*']], [[""]])
      return line
    end

    local function balance_delta(line)
      line = strip_strings_and_comments(line)
      local d = 0
      d = d + select(2, line:gsub("%(", ""))
      d = d - select(2, line:gsub("%)", ""))
      d = d + select(2, line:gsub("%[", ""))
      d = d - select(2, line:gsub("%]", ""))
      d = d + select(2, line:gsub("%{", ""))
      d = d - select(2, line:gsub("%}", ""))
      return d
    end

    local function looks_like_continuation(line)
      line = strip_strings_and_comments(line)
      local s = line:match("^%s*(.-)%s*$") or ""
      if s == "" then return false end
      if s:match("[,%+%-%*/%^=]$") then return true end
      if s:match("<%-%s*$") or s:match("=%s*$") then return true end
      if s:match("%%>%%%s*$") or s:match("|>%s*$") then return true end
      if s:match("%($") or s:match("%[$") or s:match("%{$") then return true end
      return false
    end

    -----------------------------------------------------------------
    -- 1) Find chunk lines: between nearest ```{r...} above and ``` below
    -----------------------------------------------------------------
    local function chunk_lines_between_fences()
      local buf = ev.buf
      local cur = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      local open, close

      for i = cur, 1, -1 do
        if lines[i]:match("^%s*```%s*%{%s*[Rr]") then
          open = i
          break
        end
      end

      for i = cur + 1, #lines do
        if lines[i]:match("^%s*```%s*$") then
          close = i
          break
        end
      end

      if not open or not close or open >= close then
        return nil
      end

      return vim.list_slice(lines, open + 1, close - 1)
    end

    -----------------------------------------------------------------
    -- 2) Split lines into "logical expressions"
    -----------------------------------------------------------------
    local function split_into_expressions(body_lines)
      local exprs = {}
      local cur = {}
      local bal = 0

      local function flush()
        if #cur == 0 then return end
        while #cur > 0 and is_blank(cur[#cur]) do
          table.remove(cur)
        end
        if #cur == 0 then return end
        table.insert(exprs, table.concat(cur, "\n"))
        cur = {}
        bal = 0
      end

      for _, line in ipairs(body_lines) do
        if is_blank(line) then
          if #cur > 0 and bal == 0 and not looks_like_continuation(cur[#cur]) then
            flush()
          end
        else
          table.insert(cur, line)
          bal = bal + balance_delta(line)
          if bal == 0 and not looks_like_continuation(line) then
            flush()
          end
        end
      end

      flush()
      return exprs
    end

    -----------------------------------------------------------------
    -- 3) REPL management (radian in right split)
    -----------------------------------------------------------------
    local function is_job_alive(jobid)
      if not jobid or jobid <= 0 then return false end
      local ok, info = pcall(vim.api.nvim_get_chan_info, jobid)
      return ok and info and info.id == jobid and info.stream ~= nil
    end

    local function find_existing_radian()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buftype == "terminal" then
          local name = (vim.api.nvim_buf_get_name(buf) or ""):lower()
          if name:match("radian") then
            local jobid = vim.b[buf].terminal_job_id
            if is_job_alive(jobid) then
              return jobid, buf
            end
          end
        end
      end
      return nil, nil
    end

    local function ensure_r_repl()
      local jobid = vim.g.repl_jobid_r
      if is_job_alive(jobid) then
        return jobid
      end

      local found_job = select(1, find_existing_radian())
      if is_job_alive(found_job) then
        vim.g.repl_jobid_r = found_job
        return found_job
      end

      -- start a new radian
      vim.cmd("vsplit")
      vim.cmd("wincmd l")
      vim.cmd("terminal radian")
      local new_job = vim.b.terminal_job_id
      vim.cmd("wincmd h")

      if is_job_alive(new_job) then
        vim.g.repl_jobid_r = new_job
        return new_job
      end

      return nil
    end

    -----------------------------------------------------------------
    -- 4) Bracketed-paste sender
    -----------------------------------------------------------------
    local function send_to_r(text)
      local jobid = ensure_r_repl()
      if not jobid then
        vim.notify("Could not start/find radian REPL", vim.log.levels.ERROR)
        return
      end

      if not text:match("\n$") then text = text .. "\n" end

      local PASTE_START = "\27[200~"
      local PASTE_END   = "\27[201~"

      pcall(vim.api.nvim_chan_send, jobid, PASTE_START .. text .. PASTE_END .. "\n")
    end

    -----------------------------------------------------------------
    -- 5) ⌥Enter: Run chunk as expressions
    -----------------------------------------------------------------
    local function run_chunk_as_expressions()
      local body_lines = chunk_lines_between_fences()
      if not body_lines then
        vim.notify("Not between an R chunk fence pair", vim.log.levels.WARN)
        return
      end

      local exprs = split_into_expressions(body_lines)
      if #exprs == 0 then
        vim.notify("Chunk is empty", vim.log.levels.WARN)
        return
      end

      for _, expr in ipairs(exprs) do
        send_to_r(expr)
      end
    end

    -----------------------------------------------------------------
    -- 6) Keymaps
    -----------------------------------------------------------------
    bmap({ "n", "i" }, "<M-CR>", function()
      vim.cmd("stopinsert")
      run_chunk_as_expressions()
    end, "Rmd: Send chunk as logical expressions (Option+Enter)")
  end,
})

---------------------------------------------------------------------
-- R Markdown (.Rmd/.qmd): Cmd+I → Insert R code chunk
---------------------------------------------------------------------
au("FileType", {
  group = aug("RmdChunkInsert", { clear = true }),
  pattern = { "rmd", "quarto" },
  callback = function(ev)
    vim.keymap.set({ "n", "i" }, "<D-I>", function()
      vim.cmd("stopinsert")

      local win = 0
      local buf = ev.buf
      local row = vim.api.nvim_win_get_cursor(win)[1]

      vim.api.nvim_buf_set_lines(buf, row, row, true, {
        "```{r}",
        "",
        "```",
      })

      vim.api.nvim_win_set_cursor(win, { row + 2, 0 })
      vim.cmd("startinsert")
    end, { buffer = ev.buf, silent = true, desc = "Insert R code chunk (Cmd+Shift+I)" })
  end,
})

---------------------------------------------------------------------
-- R Markdown (.Rmd/.qmd): Cmd+Shift+K → Save, Knit, then Open
---------------------------------------------------------------------
au("FileType", {
  group = aug("RMarkdownKeys", { clear = true }),
  pattern = { "rmd", "quarto" },
  callback = function()
    vim.keymap.set("n", "<D-K>", function()
      vim.cmd("write")

      local choice = vim.fn.input("Knit: (p)df / (h)tml / (d)efault ? ")
      local file = vim.fn.expand("%")
      local out_base = vim.fn.expand("%:p:r")

      local r_cmd = ""
      local out_file = nil

      if choice == "h" then
        r_cmd = "rmarkdown::render('" .. file .. "', output_format='html_document')"
        out_file = out_base .. ".html"
      elseif choice == "p" then
        r_cmd = "rmarkdown::render('" .. file .. "', output_format='pdf_document')"
        out_file = out_base .. ".pdf"
      else
        r_cmd = "rmarkdown::render('" .. file .. "')"
      end

      vim.cmd("!Rscript -e \"" .. r_cmd .. "\"")

      if vim.v.shell_error == 0 and out_file then
        vim.cmd("silent !open " .. vim.fn.shellescape(out_file))
      end
    end, { buffer = true, silent = true, desc = "Save & Knit R Markdown" })
  end,
})

---------------------------------------------------------------------
-- Markdown (.md): Pandoc
---------------------------------------------------------------------
au("FileType", {
  group = aug("MarkdownPandocKeys", { clear = true }),
  pattern = { "markdown" },
  callback = function()
    local map = function(lhs, fn, desc)
      vim.keymap.set("n", lhs, fn, { buffer = true, silent = true, desc = desc })
    end

    -- ⌘⇧K → Save + Pandoc PDF (article)
    map("<D-K>", function()
      vim.cmd("write")

      local inpath  = vim.fn.shellescape(vim.fn.expand("%:p"))
      local outpath = vim.fn.shellescape(vim.fn.expand("%:p:r") .. ".pdf")

      vim.cmd("silent !pandoc -f markdown " .. inpath ..
              " -o " .. outpath ..
              " --pdf-engine=pdflatex")

      if vim.v.shell_error == 0 then
        vim.cmd("redraw!")
        vim.cmd("silent !open " .. outpath)
      else
        vim.notify("Pandoc compilation failed.", vim.log.levels.ERROR)
      end
    end, "Pandoc → PDF (article)")

    -- ⌘⇧B → Save + Pandoc Beamer slides
    map("<D-B>", function()
      vim.cmd("write")

      local inpath  = vim.fn.shellescape(vim.fn.expand("%:p"))
      local outpath = vim.fn.shellescape(vim.fn.expand("%:p:r") .. "-slides.pdf")

      vim.cmd("silent !pandoc -f markdown " .. inpath ..
              " -t beamer" ..
              " -o " .. outpath ..
              " --pdf-engine=pdflatex")

      if vim.v.shell_error == 0 then
        vim.cmd("redraw!")
        vim.cmd("silent !open " .. outpath)
      else
        vim.notify("Pandoc compilation failed.", vim.log.levels.ERROR)
      end
    end, "Pandoc → Beamer PDF")
  end,
})
