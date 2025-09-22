local to = require("go.text_objects")

Go.op_sort_lines = function(visual_type)
  local row1, _, row2, _ = to.operator_marks(0, visual_type)
  local lines = vim.api.nvim_buf_get_lines(0, row1, row2 + 1, true)
  table.sort(
    lines,
    function(lhs, rhs)
      local ll = string.lower(lhs)
      local lr = string.lower(rhs)

      if ll == lr then
        return lhs < rhs
      else
        return ll < lr
      end
    end
  )

  vim.api.nvim_buf_set_lines(0, row1, row2 + 1, true, lines)
end

vim.keymap.set(
  "n",
  "gu",
  [[<cmd>set opfunc=v:lua.Go.op_sort_lines<cr>g@]],
  {noremap = true}
)
vim.keymap.set(
  "v",
  "gu",
  to.norm .. [[<cmd>lua Go.op_sort_lines(nil)<cr>g@]],
  {noremap = true}
)
