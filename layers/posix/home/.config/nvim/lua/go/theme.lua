local lib = require "goto.lib"

-- set terminal title
vim.opt.title = true
vim.opt.titlestring = [[「%t」]]

-- use 256 colours
vim.opt.termguicolors = true

-- remove welcome message
vim.opt.shortmess:append "AIW"

-- always show tabline
vim.opt.showtabline = 2

-- always show issues column
vim.opt.signcolumn = "yes"

-- show line count
vim.opt.number = true

-- dont show eob lines
vim.opt.fillchars = [[eob: ]]

-- always show status line
vim.opt.laststatus = 3

-- keep wrapped text indent
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = "↳"

-- constant cursor styling
vim.opt.guicursor = ""

-- completion menu transparency
vim.opt.pumblend = 5

-- float win transparency
vim.opt.winblend = 5

vim.api.nvim_create_autocmd({ "TextYankPost" }, {
  group = lib.group,
  callback = function()
    vim.hl.on_yank { higroup = "HighlightedyankRegion" }
  end,
})

-- preview height
vim.opt.previewheight = 11
