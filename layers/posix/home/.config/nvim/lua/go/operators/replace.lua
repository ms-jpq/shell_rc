local lib = require("go")
local to = require("go.text_objects")

Go.op_replace = function(visual_type)
  vim.print(visual_type)
  local row1, col1, row2, col2 = to.operator_marks(0, visual_type)
  local replacement = vim.split(vim.fn.getreg(), "\n", true) 

  vim.api.nvim_buf_set_text(0, row1, col1, row2, col2, replacement)
end

vim.keymap.set("n", "gb", [[<cmd>set opfunc=v:lua.Go.op_replace<cr>g@]], {noremap = true})
vim.keymap.set("v", "gb", to.norm .. [[<cmd>lua Go.op_replace(vim.NIL)<cr>]], {noremap = true})
