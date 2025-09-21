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
  set_visual_selection = function(win, mode, r1, c1, r2, c2, reverse)
    local cmd = [[norm! ]] .. mode
    local lo = {r1 + 1, c1}
    local hi = {r2 + 1, math.max(0, c2 - 1)}
    if reverse then
      vim.api.nvim_win_set_cursor(win, hi)
      vim.cmd(cmd)
      vim.api.nvim_win_set_cursor(win, lo)
    else
      vim.api.nvim_win_set_cursor(win, lo)
      vim.cmd(cmd)
      vim.api.nvim_win_set_cursor(win, hi)
    end
  end
}
