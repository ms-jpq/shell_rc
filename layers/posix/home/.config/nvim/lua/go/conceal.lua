local norm_cmd = [[nc]]

vim.opt.conceallevel = 2

vim.opt.concealcursor = norm_cmd

local toggle = function()
  local nxt = vim.o.concealcursor == norm_cmd and [[c]] or norm_cmd
  vim.opt.concealcursor = nxt
end

vim.keymap.set({ "n" }, [[<leader>Y]], toggle)
vim.api.nvim_create_user_command([[ToggleConcealCursor]], toggle, {})
