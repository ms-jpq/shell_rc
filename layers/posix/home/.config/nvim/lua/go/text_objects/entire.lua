local to = require "go.text_objects"

Go.op_entire = function(hold_pos)
  local restore = to.hold_position()

  local count = vim.api.nvim_buf_line_count(0)
  local last_line = unpack(vim.api.nvim_buf_get_lines(0, -2, -1, true))

  to.set_visual_selection("V", 1, 0, count, #last_line)
  if hold_pos then
    restore()
  end
end

local cmd = function(hold)
  return [[<cmd>lua Go.op_entire(]] .. tostring(hold) .. [[)<cr>]]
end

vim.keymap.set({ "o" }, "ie", cmd(true))
vim.keymap.set({ "o" }, "ae", cmd(true))
vim.keymap.set({ "x" }, "ie", to.norm .. cmd(false))
vim.keymap.set({ "x" }, "ae", to.norm .. cmd(false))
