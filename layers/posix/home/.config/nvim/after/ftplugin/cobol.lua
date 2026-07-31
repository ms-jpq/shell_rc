local autocmd = require "goto.autocmd"

vim.bo.commentstring = [[*> %s]]
vim.b.noindent = true

local enter = autocmd.buf_win({ buffer = 0 }, function()
  vim.wo.colorcolumn = "7"
end, function()
  vim.wo.colorcolumn = ""
end)
enter()
