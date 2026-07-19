local autocmd = require "go.autocmd"

vim.opt_local.formatoptions:append "ro"

local enter = autocmd.buf_win({ buffer = 0 }, function()
  vim.wo.winhighlight = "Conceal:ConcealNone"
end, function()
  vim.wo.winhighlight = ""
end)
enter()
