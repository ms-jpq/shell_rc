local autocmd = require "go.autocmd"

vim.opt_local.formatoptions:append "ro"

do
  local enter = autocmd.buf_win({ buffer = 0 }, function()
    vim.wo.winhighlight = "Conceal:ConcealNone"
  end, function()
    vim.wo.winhighlight = ""
  end)

  enter()
end

do
  local match_var = "__blockquote_match__"

  local enter = autocmd.buf_win({ buffer = 0 }, function()
    if not vim.w[match_var] then
      vim.w[match_var] = vim.fn.matchadd("@markup", [[^\s*>\%(\s*|\)\@!.*$]])
    end
  end, function()
    if vim.w[match_var] then
      vim.fn.matchdelete(vim.w[match_var])
      vim.w[match_var] = nil
    end
  end)

  enter()
end
