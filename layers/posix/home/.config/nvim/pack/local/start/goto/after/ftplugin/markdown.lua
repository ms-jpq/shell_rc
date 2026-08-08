local autocmd = require "goto.autocmd"

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
    { "@comment", [[^\s*>[ \t]*\zs|[^\n]*$]] },
    { "@comment.todo", [[^\s*>[ \t]*|[ \t]*\zs>>>[^\n]*$]] },
  }

  local enter = autocmd.buf_win({ buffer = 0 }, function()
    if not vim.w[match_var] then
      local acc = {}
      for priority, match in ipairs(matches) do
        local group, pattern = unpack(match)
        table.insert(acc, vim.fn.matchadd(group, pattern, priority))
      end
      vim.w[match_var] = acc
    end
  end, function()
    if vim.w[match_var] then
      for _, id in ipairs(vim.w[match_var]) do
        vim.fn.matchdelete(id)
      end
    end
    vim.w[match_var] = nil
  end)

  enter()
end
