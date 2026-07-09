vim.opt.conceallevel = 2

vim.opt.concealcursor = [[nc]]

local toggle = function()
  vim.opt.conceallevel = vim.o.conceallevel == 0 and 2 or 0
end

vim.keymap.set({ "n" }, [[<leader>Y]], toggle)
vim.api.nvim_create_user_command([[ToggleConcealCursor]], toggle, {})
