local M = {}

---@param row integer
---@param hunks ChecktimeHunk[]
---@param cursor boolean
---@return integer
local translate = function(row, hunks, cursor)
  local source = row - 1
  local offset = 0
  for _, hunk in ipairs(hunks) do
    if hunk.finish < source or (hunk.finish == source and (cursor or hunk.start ~= hunk.finish)) then
      offset = offset + #hunk.lines - (hunk.finish - hunk.start)
    end
  end
  return source + offset + 1
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
      local row = unpack(vim.api.nvim_win_get_cursor(win))
      views[win] = {
        reset_curswant = vim.iter(hunks):any(function(hunk)
          return hunk.start <= row - 1 and row - 1 < hunk.finish and hunk.finish - hunk.start ~= #hunk.lines
        end),
        state = vim.api.nvim_win_call(win, vim.fn.winsaveview),
      }
      return views
    end)

  return function()
    local line_count = vim.api.nvim_buf_line_count(buf)
    for win, view in pairs(views) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        view.state.lnum = math.min(translate(view.state.lnum, hunks, true), line_count)
        view.state.topline = math.min(translate(view.state.topline, hunks, false), line_count)
        local line = unpack(vim.api.nvim_buf_get_lines(buf, view.state.lnum - 1, view.state.lnum, true))
        view.state.col = math.min(view.state.col, #line)
        vim.api.nvim_win_call(win, function()
          vim.fn.winrestview(view.state)
          if view.reset_curswant then
            vim.api.nvim_win_set_cursor(win, { view.state.lnum, view.state.col })
          end
        end)
      end
    end
  end
end

return M
