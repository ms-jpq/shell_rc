local M = {}

do
  local fn_ref = vim.api.nvim_exec2(
    [[
      func s:set_opfunc(val)
          let &opfunc = a:val
      endfunc

      echon get(function('s:set_opfunc'), 'name')
    ]],
    { output = true }
  )
  M.set_opfunc = vim.fn[fn_ref.output]
end

M.norm = [[<c-\><c-n>]]

M.operator_marks = function(buf, visual_type)
  local mark1, mark2 = unpack(type(visual_type) == "string" and { "[", "]" } or { "<", ">" })

  local row1, col1 = unpack(vim.api.nvim_buf_get_mark(buf, mark1))
  local row2, col2 = unpack(vim.api.nvim_buf_get_mark(buf, mark2))

  if row1 > row2 or (row1 == row2 and col1 > col2) then
    row1, col1, row2, col2 = row2, col2, row1, col1
  end

  local last_line = unpack(vim.api.nvim_buf_get_lines(buf, row2 - 1, row2, true))
  col2 = math.min(#last_line - 1, col2)

  return row1 - 1, col1, row2 - 1, col2 + 1
end

M.translate_visual_type = function(visual_type)
  local map = { char = "v", line = "V", block = "<c-v>" }
  local mapped = map[visual_type]
  assert(mapped, visual_type)

  return mapped
end

M.set_visual_selection = function(mode, r1, c1, r2, c2, reverse)
  local lo = { r1, c1 }
  local hi = { r2, math.max(0, c2 - 1) }

  if reverse then
    vim.api.nvim_win_set_cursor(0, hi)
    vim.cmd.normal { mode, bang = true }
    vim.api.nvim_win_set_cursor(0, lo)
  else
    vim.api.nvim_win_set_cursor(0, lo)
    vim.cmd.normal { mode, bang = true }
    vim.api.nvim_win_set_cursor(0, hi)
  end
end

M.p_indent = function(line, tabsize)
  local match = string.match(line, [[^%s+]])
  if match == nil then
    return 0
  end

  local subbed = string.gsub(match, "\t", string.rep(" ", tabsize))
  return #subbed
end

M.hold_position = function()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)

  return function()
    if
      not vim.api.nvim_win_is_valid(win)
      or not vim.api.nvim_buf_is_valid(buf)
      or vim.api.nvim_win_get_buf(win) ~= buf
    then
      return
    end

    vim.api.nvim_win_call(win, function()
      vim.fn.winrestview(view)
    end)
  end
end

return M
