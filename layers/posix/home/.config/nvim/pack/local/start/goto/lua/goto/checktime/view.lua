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
      local reflow = false
      local touched = false
      for _, hunk in ipairs(hunks) do
        if hunk.start <= row - 1 and row - 1 < hunk.finish then
          touched = true
          reflow = hunk.finish - hunk.start ~= #hunk.lines
          break
        end
      end
      local wrap = false
      local state = vim.api.nvim_win_call(win, function()
        wrap = vim.wo.wrap
        return vim.fn.winsaveview()
      end)
      views[win] = { reflow = reflow, state = state, touched = touched, wrap = wrap }
      return views
    end)

  return function()
    local line_count = vim.api.nvim_buf_line_count(buf)
    for win, view in pairs(views) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        local state = view.state
        state.lnum = math.min(translate(state.lnum, hunks, true), line_count)
        state.topline = math.min(translate(state.topline, hunks, false), line_count)
        local line = unpack(vim.api.nvim_buf_get_lines(buf, state.lnum - 1, state.lnum, true))
        local col = math.min(state.col, math.max(#line - 1, 0))
        local clamped = state.col ~= col
        state.col = col
        local reset = view.reflow or (view.touched and view.wrap and clamped)
        if reset then
          state.curswant = state.col
        end
        vim.api.nvim_win_call(win, function()
          vim.fn.winrestview(state)
        end)
      end
    end
  end
end

return M
