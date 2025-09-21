local to = require("go.text_objects")

Go.op_select_line = function(is_inside)
  local row = unpack(vim.api.nvim_win_get_cursor(0))
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

  vim.print(line)
  to.set_visual_selection("v", row, lhs, row, rhs, false)
end

local cmd = function(inside)
  return [[<cmd>lua Go.op_select_line(]] .. tostring(inside) .. [[)<cr>]]
end

vim.keymap.set("o", "il", cmd(true), {noremap = true})
vim.keymap.set("o", "al", cmd(false), {noremap = true})
vim.keymap.set("v", "il", to.norm .. cmd(true), {noremap = true})
vim.keymap.set("v", "al", to.norm .. cmd(false), {noremap = true})
