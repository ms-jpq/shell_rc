Go.op_move = function(up)
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

local cmd = function(hold)
  return [[<cmd>lua Go.op_move(]] .. tostring(hold) .. [[)<cr>]]
end

vim.keymap.set("n", "<m-up>", cmd(true), {noremap = true})
vim.keymap.set("n", "<m-down>", cmd(false), {noremap = true})
