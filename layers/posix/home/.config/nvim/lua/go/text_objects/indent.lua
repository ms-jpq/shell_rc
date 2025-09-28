local to = require("go.text_objects")

local iter_lines = function(direction)
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local tabsize = vim.bo.tabstop
  local count = vim.api.nvim_buf_line_count(0)

  local init_line = unpack(vim.api.nvim_buf_get_lines(0, row, row + 1, true))
  local init_indent = to.p_indent(init_line, tabsize)

  return function()
    if row <= 0 or row >= count then
      return nil
    end

    local line = unpack(vim.api.nvim_buf_get_lines(0, row, row + 1, true))
    local empty = line == ""
    local indent = to.p_indent(line, tabsize)

    local cond1 = init_indent == 0 and empty
    local cond2 = indent < init_indent and not empty

    if cond1 or cond2 then
      return nil
    end

    local r = row
    row = row + direction
    return r, indent
  end
end

Go.op_indent = function(hold_pos)
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local hold = to.hold_position()

  local line = vim.api.nvim_get_current_line()
  local init_indent = to.p_indent(line, vim.bo.tabstop)

  local lo, hi = row, row
  for l, i in iter_lines(-1) do
    if init_indent == 0 or i ~= 0 then
      lo = l
    end
  end
  for r, i in iter_lines(1) do
    if init_indent == 0 or i ~= 0 then
      hi = r
    end
  end

  local line = unpack(vim.api.nvim_buf_get_lines(0, hi, hi + 1, true))
  to.set_visual_selection("v", lo + 1, 0, hi + 1, #line, false)

  if hold_pos then
    hold()
  end
end

local cmd = function(hold)
  return [[<cmd>lua Go.op_indent(]] .. tostring(hold) .. [[)<cr>]]
end

vim.keymap.set("o", "ii", cmd(true))
vim.keymap.set("x", "ii", to.norm .. cmd(false))
