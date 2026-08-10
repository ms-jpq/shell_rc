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
  local reflows = {}
  local touches = {}
  local wraps = {}
  local views = vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win)
      return vim.api.nvim_win_get_buf(win) == buf
    end)
    :fold({}, function(views, win)
      local row = unpack(vim.api.nvim_win_get_cursor(win))
      for _, hunk in ipairs(hunks) do
        if hunk.start <= row - 1 and row - 1 < hunk.finish then
          touches[win] = true
          reflows[win] = hunk.finish - hunk.start ~= #hunk.lines
          break
        end
      end
      views[win] = vim.api.nvim_win_call(win, function()
        wraps[win] = vim.wo.wrap
        return vim.fn.winsaveview()
      end)
      return views
    end)

  return function()
    local line_count = vim.api.nvim_buf_line_count(buf)
    for win, view in pairs(views) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        view.lnum = math.min(translate(view.lnum, hunks, true), line_count)
        view.topline = math.min(translate(view.topline, hunks, false), line_count)
        local line = unpack(vim.api.nvim_buf_get_lines(buf, view.lnum - 1, view.lnum, true))
        local col = math.min(view.col, math.max(#line - 1, 0))
        local clamped = view.col ~= col
        view.col = col
        local reset = reflows[win] or (touches[win] and wraps[win] and clamped)
        if reset then
          view.curswant = view.col
        end
        vim.api.nvim_win_call(win, function()
          vim.fn.winrestview(view)
        end)
      end
    end
  end
end

return M
