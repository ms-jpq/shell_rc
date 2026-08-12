require("goto").setup()

vim.keymap.set({ "n" }, [[<leader>Y]], [[<cmd>Go toggle-conceal<cr>]])
vim.keymap.set({ "n" }, [[<leader>w]], [[<cmd>Go repl<cr>]])
vim.keymap.set({ "n" }, [[<leader>W]], [[<cmd>Go repl-all<cr>]])
