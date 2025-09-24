local to = require("go.text_objects")

local iter_lines = function(direction)
  local row = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local tabsize = vim.bo.tabstop
  local count = vim.api.nvim_buf_line_count(0)

  local line = unpack(vim.api.nvim_buf_get_lines(0, row, row + 1, true))
  local indent = to.p_indent(line, tabsize)

  return function()
    if row <= 0 or row >= count - 1 then
      return nil
    end

    line = unpack(vim.api.nvim_buf_get_lines(0, row, row + 1, true))
    local next_indent = to.p_indent(line, tabsize)

    if (indent == 0 and #line == 0) or (next_indent < indent and #line ~= 0) then
      return nil
    end

    local r = row
    row = row + direction
    return r
  end
end

Go.op_indent = function(hold_pos)
  local row = unpack(vim.api.nvim_win_get_cursor(0))
  local hold = to.hold_position()

  local lo = row - 1
  local hi = row - 1
  for l in iter_lines(-1) do
    lo = l
  end
  for r in iter_lines(1) do
    hi = r
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

vim.keymap.set("o", "ii", cmd(true), {noremap = true})
vim.keymap.set("v", "ii", to.norm .. cmd(false), {noremap = true})
