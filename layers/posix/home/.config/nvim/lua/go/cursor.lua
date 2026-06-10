local async = require "go.async"
local lib = require "go.lib"

vim.keymap.set({ "n", "x", "o" }, "$", "$<right>")

do
  -- normalize cursor pos
  local vcol = { "onemore", "block" }
  vim.opt.virtualedit = vcol

  -- show cursor
  vim.opt.cursorline = true

  vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    group = lib.group,
    callback = function()
      vim.w.__column_highlight__ = vim.wo.cursorcolumn
      vim.opt_local.virtualedit = vcol
      vim.opt_local.cursorline = false
      vim.opt_local.cursorcolumn = false
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    group = lib.group,
    callback = function()
      local cc = vim.w.__column_highlight__
      vim.opt_local.cursorline = true
      if cc then
        vim.opt_local.cursorcolumn = cc
      end
    end,
  })

  local toggle_cursorcolumn = async(function()
    async.scheduled()

    if vim.wo.cursorcolumn then
      vim.opt_local.virtualedit = vcol
      vim.opt_local.cursorcolumn = false
    else
      vim.opt_local.virtualedit = "all"
      vim.opt_local.cursorcolumn = true
    end
  end)

  vim.keymap.set({ "n" }, [[<leader>y]], toggle_cursorcolumn)
  vim.api.nvim_create_user_command([[ToggleCursorColumn]], toggle_cursorcolumn, {})
end

vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI", "TextChangedP" }, {
  group = lib.group,
  callback = function()
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.w.__cursor_column__ = col
  end,
})

vim.api.nvim_create_autocmd({ "InsertLeave" }, {
  group = lib.group,
  callback = function()
    local col = vim.w.__cursor_column__
    if col then
      local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
      vim.api.nvim_win_set_cursor(0, { row, col })
    end
  end,
})
