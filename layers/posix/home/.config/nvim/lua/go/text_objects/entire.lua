local to = require("go.text_objects")

Go.op_around_all = function(hold_pos)
  local count = vim.api.nvim_buf_line_count(0)
  local last_line = unpack(vim.api.nvim_buf_get_lines(0, -2, -1, true))
  local pos = vim.api.nvim_win_get_cursor(0)
  to.set_visual_selection(0, "V", 0, 0, (count - 1), #last_line)

  if hold_pos then
    vim.schedule(
      function()
        vim.api.nvim_win_set_cursor(0, pos)
      end
    )
  end
end

local cmd = function(hold)
  return [[<cmd>lua Go.op_around_all(]] .. tostring(hold) .. [[)<cr>]]
end

vim.keymap.set("o", "ie", cmd(true), {noremap = true})
vim.keymap.set("o", "ae", cmd(true), {noremap = true})
vim.keymap.set("v", "ie", to.norm .. cmd(false), {noremap = true})
vim.keymap.set("v", "ae", to.norm .. cmd(false), {noremap = true})
