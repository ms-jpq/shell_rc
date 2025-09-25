vim.g.chadtree_settings = {
  xdg = true
}

vim.keymap.set("n", [[<c-t>]], [[<cmd>CHADopen<cr>]])
vim.keymap.set("n", [[<leader>z]], [[<cmd>CHADrestore<cr>]])
