local M = {}
local ns = vim.api.nvim_create_namespace "goto.checktime.view"

---@param buf integer
---@return fun(), table<integer, true>
M.capture = function(buf)
  local rows = {}

  local views = vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win)
      return vim.api.nvim_win_get_buf(win) == buf
    end)
    :fold({}, function(views, win)
      local row, col = unpack(vim.api.nvim_win_get_cursor(win))
      rows[row - 1] = true
      views[win] = {
        curswant = vim.api.nvim_win_call(win, function()
          return vim.fn.winsaveview().curswant
        end),
        id = vim.api.nvim_buf_set_extmark(buf, ns, row - 1, col, { right_gravity = true }),
      }
      return views
    end)

  return function()
    local line_count = vim.api.nvim_buf_line_count(buf)
    for win, view in pairs(views) do
      local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, view.id, {})
      local row = math.min((mark[1] or line_count - 1) + 1, line_count)
      local line = unpack(vim.api.nvim_buf_get_lines(buf, row - 1, row, true))

      vim.api.nvim_buf_del_extmark(buf, ns, view.id)
      vim.api.nvim_win_call(win, function()
        vim.api.nvim_win_set_cursor(win, { row, math.min(mark[2] or #line, #line) })
        vim.fn.winrestview { curswant = view.curswant }
      end)
    end
  end,
    rows
end

return M
