local async = require "go.async"
local lib = require "go"

vim.keymap.set({ "n", "v" }, "$", "$<right>")

do
  -- normalize cursor pos
  local vcol = { "onemore", "block" }
  vim.opt.virtualedit = vcol

  -- show cursor
  vim.opt.cursorline = true

  vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    group = lib.group,
    callback = function()
      vim.b.__column_highlight__ = vim.o.cursorcolumn
      vim.opt.virtualedit = vcol
      vim.opt.cursorline = false
      vim.opt.cursorcolumn = false
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    group = lib.group,
    callback = function()
      local cc = vim.b.__column_highlight__
      vim.opt.cursorline = true
      if cc then
        vim.opt.cursorcolumn = cc
      end
    end,
  })

  local toggle_cursorcolumn = async(function()
    async.scheduled()

    if vim.o.cursorcolumn then
      vim.opt.virtualedit = vcol
      vim.opt.cursorcolumn = false
    else
      vim.opt.virtualedit = "all"
      vim.opt.cursorcolumn = true
    end
  end)

  vim.keymap.set({ "n" }, [[<leader>y]], toggle_cursorcolumn)
  vim.api.nvim_create_user_command([[ToggleCursorColumn]], toggle_cursorcolumn, {})
end

vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI", "TextChangedP" }, {
  group = lib.group,
  callback = function()
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.b.__cursor_column__ = col
  end,
})

vim.api.nvim_create_autocmd({ "InsertLeave" }, {
  group = lib.group,
  callback = function()
    local col = vim.b.__cursor_column__
    if col then
      local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
      vim.api.nvim_win_set_cursor(0, { row, col })
    end
  end,
})
