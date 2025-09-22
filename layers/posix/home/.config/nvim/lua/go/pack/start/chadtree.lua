vim.g.chadtree_settings = {
  xdg = true
}

vim.keymap.set("n", [[<c-t>]], [[<cmd>CHADopen<cr>]], {noremap = true})
vim.keymap.set("n", [[<leader>z]], [[<cmd>CHADrestore<cr>]], {noremap = true})
