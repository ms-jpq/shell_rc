-- vimdiff options
vim.opt.diffexpr = ""
vim.opt.diffopt:append { "followwrap", "algorithm:patience" }

vim.cmd.packadd [[nvim.difftool]]
