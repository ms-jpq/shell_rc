local to = require "go.text_objects"

Go.op_sort_lines = function(visual_type)
  local row1, _, row2, _ = to.operator_marks(0, visual_type)
  local lines = vim.api.nvim_buf_get_lines(0, row1, row2 + 1, true)
  table.sort(lines, function(lhs, rhs)
    local ll = string.lower(lhs)
    local lr = string.lower(rhs)

    if ll == lr then
      return lhs < rhs
    else
      return ll < lr
    end
  end)

  vim.api.nvim_buf_set_lines(0, row1, row2 + 1, true, lines)
  local mode = to.translate_visual_type(visual_type or "line")
  if visual_type == nil then
    to.set_visual_selection(mode, row1 + 1, 0, row2 + 1, 0)
  end
end

vim.keymap.set({ "n" }, "gu", [[<cmd>set opfunc=v:lua.Go.op_sort_lines<cr>g@]])
vim.keymap.set({ "x" }, "gu", to.norm .. [[<cmd>lua Go.op_sort_lines(nil)<cr>]])
