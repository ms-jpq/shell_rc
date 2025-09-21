vim.g.chadtree_settings = {
  xdg = true
}

vim.keymap.set("n", [[<leader>v]], [[<cmd>CHADopen<cr>]], {noremap = true})
vim.keymap.set("n", [[<leader>z]], [[<cmd>CHADrestore<cr>]], {noremap = true})
