-- persistent undo
vim.opt.undofile = true

vim.cmd.packadd [[nvim.undotree]]

vim.keymap.set({ "n" }, "U", require("undotree").open)
