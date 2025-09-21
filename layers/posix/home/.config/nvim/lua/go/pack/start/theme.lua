-- https://github.com/EdenEast/nightfox.nvim

vim.opt.background = [[light]]

-- vim.cmd [[colorscheme dayfox]]
vim.cmd [[colorscheme iceberg]]

-- theme
vim.cmd("source " .. vim.fs.joinpath(vim.fn.stdpath("config"), "plugin", "theme.vim"))
