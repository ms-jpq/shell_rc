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

local add_position = function(index, text, position)
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
    add_position(index, line, { row = row })
  end
  return index
end

local token_at = function(line, col)
  local index = 1
  while true do
    local start, finish = string.find(line, "[%w_]+", index)
    if not start then
      return
    elseif start <= col + 1 and col + 1 <= finish then
      return string.sub(line, start, finish), start - 1
    end
    index = finish + 1
  end
end

local token_positions = function(lines)
  local index = {}
  for row, line in ipairs(lines) do
    local start = 1
    while true do
      local first, finish = string.find(line, "[%w_]+", start)
      if not first then
        break
      end
      add_position(index, string.sub(line, first, finish), { row = row, col = first - 1 })
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

local locator = function(after)
  local lines = line_positions(after)
  local tokens

  return function(line, col, fallback)
    local positions = lines[line]
    local offset
    if not positions then
      local token, start = token_at(line, col)
      if token then
        tokens = tokens or token_positions(after)
        positions = tokens[token]
        offset = positions and col - start or nil
      end
    end
    local target = nearest(positions, fallback)
    return {
      row = target.row,
      col = offset and target.col + offset or nil,
    }
  end
end

---@param buf integer
---@param before string[]
---@param after string[]
---@param patches ChecktimeHunk[]
---@return fun()
M.capture = function(buf, before, after, patches)
  local locate = locator(after)
  local views = vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win)
      return vim.api.nvim_win_get_buf(win) == buf
    end)
    :fold({}, function(views, win)
      local row, col = unpack(vim.api.nvim_win_get_cursor(win))
      local target = locate(before[row], col, translate(patches, row))
      views[win] = {
        row = row,
        target = target,
        topline = vim.api.nvim_win_call(win, function()
          return vim.fn.winsaveview().topline
        end),
      }
      return views
    end)

  return function()
    for win, view in pairs(views) do
      local _, col = unpack(vim.api.nvim_win_get_cursor(win))
      local row = math.min(view.target.row, vim.api.nvim_buf_line_count(buf))
      local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, true)[1]
      vim.api.nvim_win_call(win, function()
        vim.api.nvim_win_set_cursor(win, { row, math.min(view.target.col or col, #line) })
        vim.fn.winrestview { topline = view.topline + row - view.row }
      end)
    end
  end
end

return M
