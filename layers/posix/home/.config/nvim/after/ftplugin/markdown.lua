local autocmd = require "go.autocmd"

vim.opt_local.formatoptions:append "ro"

do
  local enter = autocmd.buf_win({ buffer = 0 }, function()
    vim.wo.winhighlight = "Conceal:None"
  end, function()
    vim.wo.winhighlight = ""
  end)

  enter()
end

do
  local match_var = "__blockquote_match__"

  local matches = {
    ["@markup"] = [[^\s*>\%(\s*|\)\@![^\n]*$]],
    ["@comment.todo"] = [[^\s*>\s*|\s*>>>[^\n]*$]],
  }

  local enter = autocmd.buf_win({ buffer = 0 }, function()
    local ms = vim.w[match_var] or {}
    vim.w[match_var] = ms

    for group, pattern in pairs(matches) do
      table.insert(ms, vim.fn.matchadd(group, pattern))
    end
  end, function()
    for _, id in pairs(vim.w[match_var] or {}) do
      vim.fn.matchdelete(id)
    end
    vim.w[match_var] = nil
  end)

  enter()
end
