-- lua/plugins/slime.lua
local M = {}

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------
local function half_width()
  -- Total columns of the current UI (your Ghostty terminal width when using TUI)
  return math.floor(vim.o.columns / 2)
end

local function resize_win_to_half(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local target = half_width()
  if target < 20 then
    return
  end
  pcall(vim.api.nvim_win_call, win, function()
    vim.cmd("vertical resize " .. target)
  end)
end

local function open_right_term(cmd)
  -- Open a right split terminal, but keep focus in the original (script) window.
  local curwin = vim.api.nvim_get_current_win()

  vim.cmd("vsplit")
  vim.cmd("wincmd l")
  local repl_win = vim.api.nvim_get_current_win()
  resize_win_to_half(repl_win)

  vim.cmd("terminal " .. cmd)

  local jobid = vim.b.terminal_job_id
  local term_buf = vim.api.nvim_get_current_buf()

  -- Return focus to script window
  vim.api.nvim_set_current_win(curwin)

  return jobid, term_buf
end

local function current_lang()
  local ft = vim.bo.filetype
  if ft == "python" then
    return "python"
  elseif ft == "r" or ft == "rmd" or ft == "quarto" then
    return "r"
  end
  return nil
end

local function is_blank(line)
  return line:match("^%s*$") ~= nil
end

local function is_comment(line, _lang)
  -- both R and python use '#'
  return line:match("^%s*#") ~= nil
end

local function is_chunk_fence(line)
  -- Rmd/Quarto fences like ```{r} or ``` or ```{python}
  return line:match("^%s*```") ~= nil
end

local function is_yaml_fence(line)
  -- Quarto/YAML front matter: ---
  return line:match("^%s*%-%-%-%s*$") ~= nil
end

local function next_runnable_row(bufnr, start_row, lang, ft)
  local last = vim.api.nvim_buf_line_count(bufnr)

  for r = start_row + 1, last do
    local l = vim.api.nvim_buf_get_lines(bufnr, r - 1, r, false)[1] or ""

    if not is_blank(l)
      and not is_comment(l, lang)
      and not ((ft == "rmd" or ft == "quarto") and (is_chunk_fence(l) or is_yaml_fence(l)))
    then
      return r
    end
  end

  return math.min(start_row + 1, last)
end

-----------------------------------------------------------------------
-- R "logical expression" helpers (for ⌘Enter)
-----------------------------------------------------------------------
local function strip_strings_and_comments(line)
  -- remove comments (naive but practical)
  line = line:gsub("#.*$", "")
  -- remove quoted strings to avoid counting brackets inside them
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

local function looks_like_continuation_r(line)
  line = strip_strings_and_comments(line)
  local s = line:match("^%s*(.-)%s*$") or ""
  if s == "" then return false end

  if s:match("[,%+%-%*/%^=]$") then return true end
  if s:match("<%-%s*$") or s:match("=%s*$") then return true end
  if s:match("%%>%%%s*$") or s:match("|>%s*$") then return true end
  if s:match("%($") or s:match("%[$") or s:match("%{$") then return true end

  return false
end

local function starts_with_operator_or_pipe_r(line)
  local s = (line:match("^%s*(.-)%s*$") or "")
  if s:match("^[%+%-%*/%^,]") then return true end
  if s:match("^%%>%%") or s:match("^|>") then return true end
  if s:match("^%$") or s:match("^@") then return true end
  return false
end

local function r_expression_bounds(bufnr, row)
  -- row is 1-indexed
  local ft = vim.bo[bufnr].filetype
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local n = #lines
  if n == 0 then return nil end

  local line = lines[row] or ""
  if is_blank(line)
    or is_comment(line, "r")
    or ((ft == "rmd" or ft == "quarto") and (is_chunk_fence(line) or is_yaml_fence(line)))
  then
    return nil
  end

  local start_line = row

  -- if current line begins with operator/pipe, include previous lines
  while start_line > 1 and starts_with_operator_or_pipe_r(lines[start_line]) do
    start_line = start_line - 1
  end
  -- if previous line continues, keep walking up
  while start_line > 1 and looks_like_continuation_r(lines[start_line - 1]) do
    start_line = start_line - 1
  end

  local end_line = row
  local bal = 0
  for i = start_line, end_line do
    bal = bal + balance_delta(lines[i])
  end

  while end_line < n and (bal > 0 or looks_like_continuation_r(lines[end_line])) do
    end_line = end_line + 1
    bal = bal + balance_delta(lines[end_line])
    if end_line - start_line > 400 then break end
  end

  return start_line, end_line
end

-----------------------------------------------------------------------
-- Python "logical expression" helpers (for ⌘Enter)
-----------------------------------------------------------------------
local function strip_py_strings_and_comments(line)
  -- remove comments (naive but practical)
  line = line:gsub("#.*$", "")

  -- remove triple quotes (single line cases)
  line = line:gsub([[""".-"""]], [[""]])
  line = line:gsub([['''.-''']], [[""]])

  -- remove normal strings
  line = line:gsub([["([^"\\]|\\.)*"]], [[""]])
  line = line:gsub([['([^'\\]|\\.)*']], [[""]])
  return line
end

local function py_balance_delta(line)
  line = strip_py_strings_and_comments(line)
  local d = 0
  d = d + select(2, line:gsub("%(", ""))
  d = d - select(2, line:gsub("%)", ""))
  d = d + select(2, line:gsub("%[", ""))
  d = d - select(2, line:gsub("%]", ""))
  d = d + select(2, line:gsub("%{", ""))
  d = d - select(2, line:gsub("%}", ""))
  return d
end

local function py_line_ends_with_op(line)
  line = strip_py_strings_and_comments(line)
  local s = line:match("^%s*(.-)%s*$") or ""
  if s == "" then return false end
  if s:match("[,%+%-%*/%^=]$") then return true end
  if s:match(":%s*$") then return true end
  if s:match("%(%s*$") or s:match("%[%s*$") or s:match("%{%s*$") then return true end
  if s:match("\\%s*$") then return true end -- explicit line continuation
  return false
end

local function py_is_block_header(line)
  local s = (strip_py_strings_and_comments(line):match("^%s*(.-)%s*$") or "")
  return s:match(":%s*$") ~= nil
end

local function py_indent(line)
  local sp = line:match("^(%s*)") or ""
  return #sp
end

local function py_expression_bounds(bufnr, row)
  -- row is 1-indexed
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local n = #lines
  if n == 0 then return nil end

  local line = lines[row] or ""
  if is_blank(line) or is_comment(line, "python") then
    return nil
  end

  -- Find start: walk up while previous line is clearly a continuation
  local start_line = row
  local bal = py_balance_delta(lines[start_line])

  while start_line > 1 do
    local prev = lines[start_line - 1] or ""
    if is_blank(prev) then break end

    local prev_bal = py_balance_delta(prev)
    local prev_cont = py_line_ends_with_op(prev) or (prev:match("\\%s*$") ~= nil)
    local cur_indent = py_indent(lines[start_line])
    local prev_indent = py_indent(prev)

    -- continuation via open brackets or explicit operator/line-continuation
    if bal > 0 or prev_cont then
      start_line = start_line - 1
      bal = bal + prev_bal
    -- continuation via indentation (inside a block)
    elseif cur_indent > prev_indent and not py_is_block_header(prev) then
      start_line = start_line - 1
      bal = bal + prev_bal
    else
      break
    end
  end

  -- Find end: include following lines while we're inside brackets or inside an indented block
  local end_line = row
  bal = 0
  for i = start_line, end_line do
    bal = bal + py_balance_delta(lines[i])
  end

  local base_indent = py_indent(lines[start_line])
  local block_indent = nil

  if py_is_block_header(lines[start_line]) then
    block_indent = base_indent + 1
  end

  while end_line < n do
    local nxt = lines[end_line + 1] or ""
    if is_blank(nxt) then
      if bal == 0 and not block_indent then break end
      end_line = end_line + 1
    else
      local nxt_indent = py_indent(nxt)

      -- if in brackets, always continue
      if bal > 0 then
        end_line = end_line + 1
        bal = bal + py_balance_delta(lines[end_line])
      -- if we started a block header, include indented block
      elseif py_is_block_header(lines[end_line]) then
        block_indent = py_indent(lines[end_line]) + 1
        end_line = end_line + 1
        bal = bal + py_balance_delta(lines[end_line])
      elseif block_indent and nxt_indent >= block_indent then
        end_line = end_line + 1
        bal = bal + py_balance_delta(lines[end_line])
      -- line continuation with trailing operator / backslash
      elseif py_line_ends_with_op(lines[end_line]) then
        end_line = end_line + 1
        bal = bal + py_balance_delta(lines[end_line])
      else
        break
      end
    end

    if end_line - start_line > 600 then break end
  end

  return start_line, end_line
end

-----------------------------------------------------------------------
-- REPL registry (one job id + bufnr per language)
-----------------------------------------------------------------------
local function get_jobid(lang)
  return vim.g["repl_jobid_" .. lang]
end

local function set_jobid(lang, id)
  vim.g["repl_jobid_" .. lang] = id
end

local function get_bufnr(lang)
  return vim.g["repl_bufnr_" .. lang]
end

local function set_bufnr(lang, buf)
  vim.g["repl_bufnr_" .. lang] = buf
end

local function is_job_alive(jobid)
  if not jobid or jobid <= 0 then
    return false
  end
  local ok, info = pcall(vim.api.nvim_get_chan_info, jobid)
  return ok and info and info.id == jobid and info.stream ~= nil
end

local function buf_is_valid(buf)
  return buf and type(buf) == "number" and buf > 0 and vim.api.nvim_buf_is_valid(buf)
end

local function win_showing_buf(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
  return nil
end

local function show_repl_buffer_on_right(buf)
  -- If already visible, do nothing (but still enforce width).
  if not buf_is_valid(buf) then
    return nil
  end

  local existing = win_showing_buf(buf)
  if existing then
    resize_win_to_half(existing)
    return existing
  end

  -- Open right split showing that buffer, but keep focus in current window.
  local curwin = vim.api.nvim_get_current_win()

  vim.cmd("vsplit")
  vim.cmd("wincmd l")
  local repl_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(repl_win, buf)
  resize_win_to_half(repl_win)

  vim.api.nvim_set_current_win(curwin)
  return repl_win
end

-- Find an existing terminal buffer whose name contains a token
local function find_term_jobid(token)
  token = token:lower()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "terminal" then
      local name = vim.api.nvim_buf_get_name(buf):lower()
      if name:match(token) then
        local jobid = vim.b[buf].terminal_job_id
        if is_job_alive(jobid) then
          return jobid, buf
        end
      end
    end
  end
  return nil, nil
end

-----------------------------------------------------------------------
-- Ensure REPL exists
-----------------------------------------------------------------------
local function ensure_repl(lang)
  local jobid = get_jobid(lang)

  -- If we have a cached jobid, verify it is still alive
  if is_job_alive(jobid) then
    -- If user :q closed the terminal WINDOW, the REPL is still alive
    -- but not visible; show it again without stealing focus, and enforce width.
    local buf = get_bufnr(lang)
    if buf_is_valid(buf) then
      show_repl_buffer_on_right(buf)
    end
    return jobid
  end

  -- cached job is dead -> clear it
  set_jobid(lang, nil)
  set_bufnr(lang, nil)

  -- Try to discover an existing live terminal (in case user started it manually)
  local found_job, found_buf
  if lang == "r" then
    found_job, found_buf = find_term_jobid("radian")
    if not found_job then
      found_job, found_buf = find_term_jobid(" r")
    end
    if not found_job then
      found_job, found_buf = find_term_jobid("R")
    end
  elseif lang == "python" then
    found_job, found_buf = find_term_jobid("ipython")
    if not found_job then
      found_job, found_buf = find_term_jobid("python")
    end
  end

  if is_job_alive(found_job) then
    set_jobid(lang, found_job)
    set_bufnr(lang, found_buf)
    if buf_is_valid(found_buf) then
      show_repl_buffer_on_right(found_buf)
    end
    return found_job
  end

  -- Otherwise start a new one on the right (and KEEP focus in script)
  local new_jobid, term_buf
  if lang == "r" then
    new_jobid, term_buf = open_right_term("radian")
  elseif lang == "python" then
    new_jobid, term_buf = open_right_term("ipython")
  end

  if is_job_alive(new_jobid) then
    set_jobid(lang, new_jobid)
    set_bufnr(lang, term_buf)
    return new_jobid
  end

  return nil
end

-----------------------------------------------------------------------
-- Send to REPL
-----------------------------------------------------------------------
local function send_to_repl(lang, text)
  local jobid = ensure_repl(lang)
  if not jobid then
    vim.notify(
      ("REPL job not found for %s. Is it installed and on PATH?"):format(lang),
      vim.log.levels.ERROR
    )
    return
  end

  if not text:match("\n$") then
    text = text .. "\n"
  end

  -- Bracketed paste so multi-line expressions don't behave like line-by-line typing
  local PASTE_START = "\27[200~"
  local PASTE_END   = "\27[201~"

  local payload = PASTE_START .. text .. PASTE_END .. "\n"

  -- Send, but tolerate rare race where channel dies after ensure_repl
  local ok = pcall(vim.api.nvim_chan_send, jobid, payload)
  if not ok then
    set_jobid(lang, nil)
    set_bufnr(lang, nil)
    jobid = ensure_repl(lang)
    if jobid then
      pcall(vim.api.nvim_chan_send, jobid, payload)
    end
  end
end

-----------------------------------------------------------------------
-- Send current expression (R/python) / line (others) + advance
-----------------------------------------------------------------------
local function send_current_and_advance(lang)
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype
  local row = vim.api.nvim_win_get_cursor(0)[1]

  if lang == "r" then
    local s, e = r_expression_bounds(bufnr, row)
    if not s or not e then
      local nr = next_runnable_row(bufnr, row, lang, ft)
      vim.api.nvim_win_set_cursor(0, { nr, 0 })
      return
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, s - 1, e, false)
    send_to_repl(lang, table.concat(lines, "\n"))

    local nr = next_runnable_row(bufnr, e, lang, ft)
    vim.api.nvim_win_set_cursor(0, { nr, 0 })
    return
  elseif lang == "python" then
    local s, e = py_expression_bounds(bufnr, row)
    if not s or not e then
      local nr = next_runnable_row(bufnr, row, lang, ft)
      vim.api.nvim_win_set_cursor(0, { nr, 0 })
      return
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, s - 1, e, false)
    send_to_repl(lang, table.concat(lines, "\n"))

    local nr = next_runnable_row(bufnr, e, lang, ft)
    vim.api.nvim_win_set_cursor(0, { nr, 0 })
    return
  end

  -- default: original behavior (line-based)
  local line = vim.api.nvim_get_current_line()

  if is_blank(line)
    or is_comment(line, lang)
    or ((ft == "rmd" or ft == "quarto") and (is_chunk_fence(line) or is_yaml_fence(line)))
  then
    local nr = next_runnable_row(bufnr, row, lang, ft)
    vim.api.nvim_win_set_cursor(0, { nr, 0 })
    return
  end

  send_to_repl(lang, line)

  local nr = next_runnable_row(bufnr, row, lang, ft)
  vim.api.nvim_win_set_cursor(0, { nr, 0 })
end

local function send_visual_selection(lang)
  local s = vim.fn.getpos("'<")[2]
  local e = vim.fn.getpos("'>")[2]
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  if #lines == 0 then
    return
  end
  send_to_repl(lang, table.concat(lines, "\n"))
end

-----------------------------------------------------------------------
-- Setup
-----------------------------------------------------------------------
function M.setup()
  -- Auto-clear cached repl targets when their terminal buffer closes (job actually exits)
  vim.api.nvim_create_autocmd("TermClose", {
    callback = function(ev)
      for _, lang in ipairs({ "r", "python" }) do
        if get_bufnr(lang) == ev.buf then
          set_jobid(lang, nil)
          set_bufnr(lang, nil)
        end
      end
    end,
  })

  -- Always keep REPL exactly half-width when the UI is resized.
  -- (VimResized fires when terminal window changes size.)
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      for _, lang in ipairs({ "r", "python" }) do
        local buf = get_bufnr(lang)
        if buf_is_valid(buf) then
          local win = win_showing_buf(buf)
          if win then
            resize_win_to_half(win)
          end
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "r", "rmd", "quarto", "python" },
    callback = function(ev)
      local lang = current_lang()
      if not lang then
        return
      end

      local opts = { buffer = ev.buf, silent = true }

      -- ⌘ + Enter: run current expression (R/python) / current line (others) and advance
      vim.keymap.set("n", "<D-CR>", function()
        send_current_and_advance(lang)
      end, opts)

      vim.keymap.set("x", "<D-CR>", function()
        -- leave visual mode
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
          "n",
          true
        )
        send_visual_selection(lang)
      end, opts)

      -- Open REPL explicitly (and show it if hidden)
      vim.keymap.set("n", "<localleader>rr", function()
        ensure_repl(lang)
      end, vim.tbl_extend("force", opts, { desc = "Open REPL on right" }))

      -- Clear REPL target
      vim.keymap.set("n", "<localleader>rR", function()
        set_jobid(lang, nil)
        set_bufnr(lang, nil)
        vim.notify("Cleared REPL target for " .. lang)
      end, vim.tbl_extend("force", opts, { desc = "Clear REPL target" }))
    end,
  })
end

return M
