local lib = require("go")

vim.api.nvim_create_autocmd({"TermOpen"}, {group = lib.group, command = [[startinsert]]})

vim.api.nvim_create_autocmd({"TermLeave"}, {group = lib.group, command = [[set nomodified]]})
