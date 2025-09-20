-- normalize cursor pos
local vcol = {"onemore", "block"}
vim.opt.virtualedit = vcol

-- show cursor
vim.opt.cursorline = true

vim.api.nvim_create_autocmd(
  "InsertEnter",
  {
    callback = function()
      vim.opt.virtualedit = vcol
      vim.opt.cursorline = false
      vim.opt.cursorcolumn = false
    end
  }
)
vim.api.nvim_create_autocmd(
  "InsertLeave",
  {
    callback = function()
      vim.opt.cursorline = true
    end
  }
)

vim.keymap.set(
  "n",
  "<leader>f",
  function()
    if vim.opt.cursorcolumn then
      vim.opt.virtualedit = vcol
      vim.opt.cursorcolumn = false
    else
      vim.opt.virtualedit = "all"
      vim.opt.cursorcolumn = true
    end
  end,
  {
    noremap = true
  }
)

for _, mode in pairs {"n", "v"} do
  vim.keymap.set(mode, "$", "$<right>", {noremap = true})
end

vim.api.nvim_create_autocmd(
  {"InsertEnter", "CursorMovedI", "TextChangedP"},
  {
    callback = function()
      local _, col = unpack(vim.api.nvim_win_get_cursor(0))
      vim.b.__cursor_column__ = col
    end
  }
)

vim.api.nvim_create_autocmd(
  {"InsertLeave"},
  {
    callback = function()
      local col = vim.b.__cursor_column__
      if col then
        local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
        vim.api.nvim_win_set_cursor(0, {row, col})
      end
    end
  }
)
