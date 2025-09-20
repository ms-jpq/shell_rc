-- use buffer text for folds
vim.opt.foldtext = ""

-- close nested folds above this level
vim.opt.foldlevel = 9

-- auto open / close folds
vim.opt.foldopen:append {"insert", "jump"}
-- vim.opt.foldclose = "all"
