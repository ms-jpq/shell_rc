local async = require "go.async"

local fn_ref = vim.api.nvim_exec2(
  [[
    func s:set_opfunc(val)
        let &opfunc = a:val
    endfunc

    echon get(function('s:set_opfunc'), 'name')
  ]],
  { output = true }
)

return {
  set_opfunc = vim.fn[fn_ref.output],
  norm = [[<c-\><c-n>]],
  operator_marks = function(buf, visual_type)
    local mark1, mark2 = unpack(type(visual_type) == "string" and { "[", "]" } or { "<", ">" })

    local row1, col1 = unpack(vim.api.nvim_buf_get_mark(buf, mark1))
    local row2, col2 = unpack(vim.api.nvim_buf_get_mark(buf, mark2))

    local last_line = unpack(vim.api.nvim_buf_get_lines(buf, row2 - 1, row2, true))
    col2 = math.min(#last_line - 1, col2)

    return row1 - 1, col1, row2 - 1, col2 + 1
  end,
  translate_visual_type = function(visual_type)
    local map = { char = "v", line = "V", block = "<c-v>" }
    local mapped = map[visual_type]
    assert(mapped, visual_type)

    return mapped
  end,
  set_visual_selection = function(mode, r1, c1, r2, c2, reverse)
    local cmd = [[norm! ]] .. mode
    local lo = { r1, c1 }
    local hi = { r2, math.max(0, c2 - 1) }

    if reverse then
      vim.api.nvim_win_set_cursor(0, hi)
      vim.cmd(cmd)
      vim.api.nvim_win_set_cursor(0, lo)
    else
      vim.api.nvim_win_set_cursor(0, lo)
      vim.cmd(cmd)
      vim.api.nvim_win_set_cursor(0, hi)
    end
  end,
  p_indent = function(line, tabsize)
    local match = string.match(line, [[^%s+]])
    if match == nil then
      return 0
    end

    local tabs = {}
    for _ = 1, tabsize do
      table.insert(tabs, " ")
    end
    local subbed = string.gsub(match, "\t", table.concat(tabs, ""))
    return #subbed
  end,
  hold_position = function()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    return async(function()
      async.scheduled()

      local count = vim.api.nvim_buf_line_count(buf)
      row = math.min(row, count)
      local line = unpack(vim.api.nvim_buf_get_lines(buf, row - 1, row, true))

      vim.api.nvim_win_set_cursor(win, { row, math.min(col, #line) })
    end)
  end,
}
