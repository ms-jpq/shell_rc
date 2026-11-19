require("goto").setup()

vim.keymap.set({ "n" }, [[<leader>y]], [[<cmd>Go toggle-conceal<cr>]])
vim.keymap.set("n", [[<leader>w]], [[<cmd>Go repl<cr>]])
vim.keymap.set("x", [[<leader>w]], [[:Go repl<cr>]])
vim.keymap.set("n", [[<leader>W]], [[<cmd>Go repl-all<cr>]])
vim.keymap.set("x", [[<leader>W]], [[:Go repl-all<cr>]])
