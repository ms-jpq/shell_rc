local fn_ref =
  vim.api.nvim_exec2(
  [[
    func s:set_opfunc(val)
        let &opfunc = a:val
    endfunc

    echon get(function('s:set_opfunc'), 'name')
  ]],
  {output = true}
)

return {
  set_opfunc = vim.fn[fn_ref.output],
  norm = [[<c-\><c-n>]],
  operator_marks = function(buf, visual_type)
    local mark1, mark2 = unpack(visual_type and {"[", "]"} or {"<", ">"})

    local row1, col1 = unpack(vim.api.nvim_buf_get_mark(buf, mark1))
    local row2, col2 = unpack(vim.api.nvim_buf_get_mark(buf, mark2))

    return {row1 - 1, col1, row2 - 1, col2 + 1}
  end,
  set_visual_selection = function(mode, r1, c1, r2, c2, reverse)
    local cmd = [[norm! ]] .. mode
    local lo = {r1, c1}
    local hi = {r2, math.max(0, c2 - 1)}

    if reverse then
      vim.api.nvim_win_set_cursor(0, hi)
      vim.cmd(cmd)
      vim.api.nvim_win_set_cursor(0, lo)
    else
      vim.api.nvim_win_set_cursor(0, lo)
      vim.cmd(cmd)
      vim.api.nvim_win_set_cursor(0, hi)
    end
  end
}
