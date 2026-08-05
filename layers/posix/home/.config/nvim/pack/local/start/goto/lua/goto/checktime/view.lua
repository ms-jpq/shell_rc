local M = {}
local ns = vim.api.nvim_create_namespace "goto.checktime.view"

---@param buf integer
---@return table<integer, true>, fun()
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

  return rows,
    function()
      local line_count = vim.api.nvim_buf_line_count(buf)
      for win, view in pairs(views) do
        local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, view.id, {})
        vim.api.nvim_buf_del_extmark(buf, ns, view.id)

        local r, c = unpack(mark)
        local row = math.min((r or line_count - 1) + 1, line_count)
        local line = unpack(vim.api.nvim_buf_get_lines(buf, row - 1, row, true))
        local col = math.min(c or #line, #line)

        vim.api.nvim_win_call(win, function()
          vim.fn.winrestview { lnum = row, col = col, curswant = view.curswant }
        end)
      end
    end
end

return M
