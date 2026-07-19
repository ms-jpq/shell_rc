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
  local windows = {}

  local enter = autocmd.buf_win({ buffer = 0 }, function()
    local win = vim.api.nvim_get_current_win()
    local match = windows[win]

    if match then
      vim.fn.matchdelete(match, win)
    end
    windows[win] = vim.fn.matchadd("markdownBlockquote", [[^\s*>\%(\s*|\)\@!.*$]])
  end, function()
    local win = vim.api.nvim_get_current_win()
    local match = windows[win]

    if match then
      vim.fn.matchdelete(match, win)
    end
    windows[win] = nil
  end)

  enter()
end
