local M = {}
---@param row integer
---@param hunks ChecktimeHunk[]
---@param cursor boolean
---@return integer
local translate = function(row, hunks, cursor)
  local index = row - 1
  for _, hunk in ipairs(hunks) do
    if hunk.finish < index or (hunk.finish == index and (cursor or hunk.start ~= hunk.finish)) then
      index = index + #hunk.lines - (hunk.finish - hunk.start)
    end
  end
  return index + 1
end

---@param buf integer
---@param hunks ChecktimeHunk[]
---@return fun()
M.capture = function(buf, hunks)
  local views = vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win)
      return vim.api.nvim_win_get_buf(win) == buf
    end)
    :fold({}, function(views, win)
      views[win] = vim.api.nvim_win_call(win, vim.fn.winsaveview)
      return views
    end)

  return function()
    local line_count = vim.api.nvim_buf_line_count(buf)
    for win, view in pairs(views) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        view.lnum = math.min(translate(view.lnum, hunks, true), line_count)
        view.topline = math.min(translate(view.topline, hunks, false), line_count)
        local line = unpack(vim.api.nvim_buf_get_lines(buf, view.lnum - 1, view.lnum, true))
        view.col = math.min(view.col, #line)
        vim.api.nvim_win_call(win, function()
          vim.fn.winrestview(view)
          vim.api.nvim_win_set_cursor(win, { view.lnum, view.col })
        end)
      end
    end
  end
end

return M
