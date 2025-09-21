local to = require("go.text_objects")

Go.op_entire = function(hold_pos)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)

  local count = vim.api.nvim_buf_line_count(buf)
  local last_line = unpack(vim.api.nvim_buf_get_lines(buf, -2, -1, true))
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))

  to.set_visual_selection("V", 1, 0, count, #last_line)

  if hold_pos then
    vim.schedule(
      function()
        local max_rows = vim.api.nvim_buf_line_count(buf)
        row = math.min(row, max_rows)
        local line = unpack(vim.api.nvim_buf_get_lines(buf, row - 1, row, true))

        vim.api.nvim_win_set_cursor(win, {row, math.min(col, #line)})
      end
    )
  end
end

local cmd = function(hold)
  return [[<cmd>lua Go.op_entire(]] .. tostring(hold) .. [[)<cr>]]
end

vim.keymap.set("o", "ie", cmd(true), {noremap = true})
vim.keymap.set("o", "ae", cmd(true), {noremap = true})
vim.keymap.set("v", "ie", to.norm .. cmd(false), {noremap = true})
vim.keymap.set("v", "ae", to.norm .. cmd(false), {noremap = true})
