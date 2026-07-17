local async = require "go.async"
local to = require "go.text_objects"

local iter_around_lines = function(is_inside, tabsize, row, init_indent, direction)
  local count = vim.api.nvim_buf_line_count(0)

  return function()
    if row < 0 or row >= count then
      return nil
    end

    local line = unpack(vim.api.nvim_buf_get_lines(0, row, row + 1, true))
    local empty = line == ""
    local indent = to.p_indent(line, tabsize)

    if is_inside then
      if indent ~= init_indent or empty then
        return nil
      end
    else
      if (init_indent == 0 and empty) or (indent < init_indent and not empty) then
        return nil
      end
    end

    local r = row
    row = row + direction
    return r, indent
  end
end

Go.op_indent = async(function(hold_pos, is_inside)
  local tabsize = vim.bo.tabstop
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1

  local restore = to.hold_position()

  local line = unpack(vim.api.nvim_buf_get_lines(0, row, row + 1, true))
  local indent = to.p_indent(line, tabsize)

  local lo, hi = row, row
  for l, i in iter_around_lines(is_inside, tabsize, row, indent, -1) do
    if indent == 0 or i ~= 0 then
      lo = l
    end
  end
  for r, i in iter_around_lines(is_inside, tabsize, row, indent, 1) do
    if indent == 0 or i ~= 0 then
      hi = r
    end
  end

  local last = unpack(vim.api.nvim_buf_get_lines(0, hi, hi + 1, true))
  to.set_visual_selection("v", lo + 1, 0, hi + 1, #last, false)

  if hold_pos then
    async.scheduled()
    restore()
  end
end)

local cmd = function(hold, inside)
  return [[<cmd>lua Go.op_indent(]] .. tostring(hold) .. "," .. tostring(inside) .. [[)<cr>]]
end

vim.keymap.set({ "o" }, "ii", cmd(true, true))
vim.keymap.set({ "x" }, "ii", to.norm .. cmd(false, true))
vim.keymap.set({ "o" }, "ai", cmd(true, false))
vim.keymap.set({ "x" }, "ai", to.norm .. cmd(false, false))
