local to = require("go.text_objects")

Go.op_replace = function(visual_type)
  local row1, col1, row2, col2 = to.operator_marks(0, visual_type)
  local replacement = vim.split(vim.fn.getreg(), "\n", true)

  vim.api.nvim_buf_set_text(0, row1, col1, row2, col2, replacement)
end

vim.keymap.set("n", "gb", [[<cmd>set opfunc=v:lua.Go.op_replace<cr>g@]])
vim.keymap.set("x", "gb", to.norm .. [[<cmd>lua Go.op_replace(nil)<cr>]])

local replace_line = function()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local text = string.gsub(vim.fn.getreg(), [[^%s+|%s+$]], "")
  local lines = vim.split(text, "\n", true)

  vim.api.nvim_buf_set_lines(0, row - 1, row, true, lines)
end

vim.keymap.set("n", "gbb", replace_line)
