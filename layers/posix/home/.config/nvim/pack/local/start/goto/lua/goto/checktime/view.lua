local M = {}

---@class ChecktimePosition
---@field row integer
---@field col? integer

local translate = function(patches, row)
  row = row - 1
  local shift = 0

  for _, hunk in ipairs(patches) do
    local old_count = hunk.finish - hunk.start
    if row < hunk.start then
      break
    elseif old_count == 0 then
      shift = shift + #hunk.lines
    elseif row >= hunk.finish then
      shift = shift + #hunk.lines - old_count
    else
      return row + shift + 1
    end
  end

  return row + shift + 1
end

local insert = function(index, text, position)
  local positions = index[text]
  if positions then
    table.insert(positions, position)
  else
    index[text] = { position }
  end
end

local line_positions = function(lines)
  local index = {}
  for row, line in ipairs(lines) do
    insert(index, line, { row = row })
  end
  return index
end

local token_at = function(line, col)
  local index = 1
  while true do
    local start, finish = line:find("[%w_]+", index)
    if not start then
      return
    elseif start <= col + 1 and col + 1 <= finish then
      return line:sub(start, finish), start - 1
    end
    index = finish + 1
  end
end

local token_positions = function(lines)
  local index = {}
  for row, line in ipairs(lines) do
    local start = 1
    while true do
      local first, finish = line:find("[%w_]+", start)
      if not first then
        break
      end
      insert(index, line:sub(first, finish), { row = row, col = first - 1 })
      start = finish + 1
    end
  end
  return index
end

local nearest = function(positions, row)
  if not positions then
    return { row = row }
  end

  local nearest = positions[1]
  for _, position in ipairs(positions) do
    if math.abs(position.row - row) < math.abs(nearest.row - row) then
      nearest = position
    end
  end
  return nearest
end

---@param buf integer
---@param before string[]
---@param after string[]
---@param patches ChecktimeHunk[]
---@return fun()
M.capture = function(buf, before, after, patches)
  local lines = line_positions(after)
  local tokens
  local views = vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win)
      return vim.api.nvim_win_get_buf(win) == buf
    end)
    :fold({}, function(views, win)
      local row, col = unpack(vim.api.nvim_win_get_cursor(win))
      local positions = lines[before[row]]
      local offset
      if not positions then
        tokens = tokens or token_positions(after)
        local token, start = token_at(before[row], col)
        if token then
          positions = tokens[token]
          offset = positions and col - start or nil
        end
      end
      local target = nearest(positions, translate(patches, row))
      views[win] = {
        row = row,
        target = target.row,
        col = offset and target.col + offset or nil,
        topline = vim.api.nvim_win_call(win, function()
          return vim.fn.winsaveview().topline
        end),
      }
      return views
    end)

  return function()
    for win, view in pairs(views) do
      local _, col = unpack(vim.api.nvim_win_get_cursor(win))
      local row = math.min(view.target, vim.api.nvim_buf_line_count(buf))
      local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, true)[1]
      vim.api.nvim_win_call(win, function()
        vim.api.nvim_win_set_cursor(win, { row, math.min(view.col or col, #line) })
        vim.fn.winrestview { topline = view.topline + row - view.row }
      end)
    end
  end
end

return M
