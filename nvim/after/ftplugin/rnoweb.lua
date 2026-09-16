local function open_pdf(pdf)
  if vim.fn.filereadable(pdf) ~= 1 then
    vim.notify("Rnw PDF not found: " .. pdf, vim.log.levels.WARN)
    return
  end

  vim.fn.jobstart({ "open", "-a", "Skim", pdf }, { detach = true })
end

local function close_build_terminal(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
  end
end

local function insert_r_chunk()
  vim.cmd.stopinsert()

  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  vim.api.nvim_buf_set_lines(bufnr, row, row, true, {
    "<<>>=",
    "",
    "@",
  })

  vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
  vim.cmd.startinsert()
end

local function render_rnw()
  vim.cmd.update()

  local input = vim.api.nvim_buf_get_name(0)
  if input == "" then
    vim.notify("Save the Rnw file before rendering", vim.log.levels.WARN)
    return
  end

  local dir = vim.fs.dirname(input)
  local name = vim.fn.fnamemodify(input, ":t:r")
  local pdf = vim.fs.joinpath(dir, name .. ".pdf")
  local expression = ("knitr::knit2pdf(%s, clean = FALSE)"):format(vim.json.encode(input))

  vim.cmd("botright 12new")
  local terminal_buf = vim.api.nvim_get_current_buf()
  vim.fn.termopen({ "Rscript", "-e", expression }, {
    cwd = dir,
    on_exit = function(_, code)
      if code ~= 0 then
        return
      end

      vim.schedule(function()
        close_build_terminal(terminal_buf)
        vim.notify("Rnw rendered successfully")
        open_pdf(pdf)
      end)
    end,
  })
  vim.cmd.startinsert()
end

vim.keymap.set("n", "<localleader>ll", render_rnw, {
  buffer = true,
  desc = "Knit Rnw to PDF",
})

vim.keymap.set("n", "<localleader>lv", function()
  local input = vim.api.nvim_buf_get_name(0)
  if input == "" then
    vim.notify("Save the Rnw file before viewing its PDF", vim.log.levels.WARN)
    return
  end

  open_pdf(vim.fn.fnamemodify(input, ":r") .. ".pdf")
end, {
  buffer = true,
  desc = "View Rnw PDF",
})

vim.keymap.set("n", "<F5>", render_rnw, {
  buffer = true,
  desc = "Knit Rnw to PDF",
})

vim.keymap.set({ "n", "i" }, "<D-I>", insert_r_chunk, {
  buffer = true,
  silent = true,
  desc = "Insert Rnw code chunk (Cmd+Shift+I)",
})
