local to = require("go.text_objects")

Go.op_norm_move = function(up)
  local row = unpack(vim.api.nvim_win_get_cursor(0))
  local count = vim.api.nvim_buf_line_count(0)

  if up then
    if row > 1 then
      vim.cmd [[move -2]]
    end
  else
    if row < count then
      vim.cmd [[move +1]]
    end
  end
end

local cmd = function(name, hold)
  return [[<cmd>lua Go.]] .. name .. [[(]] .. tostring(hold) .. [[)<cr>]]
end

vim.keymap.set("n", "<m-up>", cmd("op_norm_move", true), {noremap = true})
vim.keymap.set("n", "<m-down>", cmd("op_norm_move", false), {noremap = true})

Go.op_visual_move = function(up)
  local row = unpack(vim.api.nvim_win_get_cursor(0))
  local row1, col1, row2, col2 = unpack(to.operator_marks(0, nil))
  local count = vim.api.nvim_buf_line_count(0)

  if up then
    if row <= 1 then
      vim.cmd [[norm! gv]]
    else
      vim.cmd(row1 + 1 .. "," .. row2 + 1 .. "move " .. row1 - 1)
      to.set_visual_selection(0, "v", row1 - 1, col1, row2 - 1, col2, true)
    end
  else
    if row2 + 1 >= count then
      vim.cmd [[norm! gv]]
    else
      vim.cmd(row1 + 1 .. "," .. row2 + 1 .. "move " .. row2 + 2)
      to.set_visual_selection(0, "v", row1 + 1, col1, row2 + 1, col2, true)
    end
  end
end

vim.keymap.set("v", "<m-up>", to.norm .. cmd("op_visual_move", true), {noremap = true})
vim.keymap.set(
  "v",
  "<m-down>",
  to.norm .. cmd("op_visual_move", false),
  {noremap = true}
)
