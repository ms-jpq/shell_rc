vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"

vim.keymap.set({"x", "o"}, "+", "an", {remap = true})
vim.keymap.set({"x", "o"}, "_", "in", {remap = true})
