local async = require "goto.async"
local to = require "go.text_objects"

Go.op_select_line = async(function(hold_pos, is_inside)
  local restore = to.hold_position()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local line = unpack(vim.api.nvim_buf_get_lines(0, row - 1, row, true))

  local lhs = 0
  local rhs = 0
  if is_inside then
    lhs = #line - #string.gsub(line, [[^%s+]], "")
    rhs = #string.gsub(line, [[%s+$]], "")
  else
    lhs = 0
    rhs = #line + 1
  end

  to.set_visual_selection("v", row, lhs, row, rhs, false)
  if hold_pos then
    async.scheduled()
    restore()
  end
end)

local cmd = function(hold_pos, inside)
  return [[<cmd>lua Go.op_select_line(]] .. tostring(hold_pos) .. "," .. tostring(inside) .. [[)<cr>]]
end

vim.keymap.set({ "o" }, "il", cmd(true, true))
vim.keymap.set({ "o" }, "al", cmd(true, false))
vim.keymap.set({ "x" }, "il", to.norm .. cmd(false, true))
vim.keymap.set({ "x" }, "al", to.norm .. cmd(false, false))
