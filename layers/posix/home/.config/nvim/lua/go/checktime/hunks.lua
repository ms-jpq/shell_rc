local lib = require "go.lib"

local M = {}

---@alias ChecktimePosition integer[]

---@class ChecktimeHunk
---@field start integer
---@field finish integer
---@field lines string[]
---@field slot? integer

---@class ChecktimeHunkGroup
---@field local_patches ChecktimeHunk[]
---@field remote_patches ChecktimeHunk[]

local records = function(linefeed, text)
  if text == "" then
    return {}
  end

  local parts = vim.split(text, linefeed, { plain = true })
  local records = {}
  for index = 1, #parts - 1 do
    table.insert(records, parts[index] .. linefeed)
  end
  if text:sub(-#linefeed) ~= linefeed then
    table.insert(records, parts[#parts])
  end
  return records
end

local chars = function(pieces)
  return vim.fn.split(table.concat(pieces), [[\zs]])
end

local buffer_lines = function(linefeed, text, final_empty)
  local lines = vim
    .iter(records(linefeed, text))
    :map(function(record)
      return string.sub(record, -#linefeed) == linefeed and string.sub(record, 1, -#linefeed - 1) or record
    end)
    :totable()
  if final_empty and string.sub(text, -#linefeed) == linefeed then
    table.insert(lines, "")
  end
  return lines
end

local split = function(hunk)
  local old_count = hunk.finish - hunk.start
  local count = math.max(old_count, #hunk.lines)
  local patches = {}

  for index = 0, count - 1 do
    local start = hunk.start + math.min(index, old_count)
    table.insert(patches, {
      start = start,
      finish = start + (index < old_count and 1 or 0),
      lines = index < #hunk.lines and { hunk.lines[index + 1] } or {},
      slot = index < old_count and nil or index - old_count,
    })
  end

  return patches
end

local slice = function(lines, start, finish)
  return vim.list_slice(lines, math.floor(start + 1), math.floor(finish))
end

local diff = function(separator, before, after)
  return vim
    .iter(vim.text.diff(table.concat(before, separator), table.concat(after, separator), { result_type = "indices" }))
    :map(function(hunk)
      local old_start, old_count, new_start, new_count = unpack(hunk)
      local start = old_start - (old_count == 0 and 0 or 1)
      return {
        start = start,
        finish = start + old_count,
        lines = slice(after, new_start - 1, new_start + new_count - 1),
      }
    end)
    :totable()
end

local diff_hunks = function(separator, before, after, atomic)
  local changes = diff(separator, before, after)
  if atomic then
    return vim.iter(changes):map(split):flatten():totable()
  end
  return changes
end

local row_hunks = function(before, after)
  return diff_hunks("", before, after, true)
end

local overlaps = function(left, right)
  if left.start == left.finish and right.start == right.finish then
    return left.start == right.start and left.slot == right.slot
  elseif left.start == left.finish then
    return right.start < left.start and left.start < right.finish
  elseif right.start == right.finish then
    return left.start < right.start and right.start < left.finish
  end
  return left.start < right.finish and right.start < left.finish
end

local patch = function(base, patches)
  local lines = slice(base, 0, #base)

  for hunk in vim.iter(patches):rev() do
    for _ = hunk.start, hunk.finish - 1 do
      table.remove(lines, hunk.start + 1)
    end
    for index = #hunk.lines, 1, -1 do
      table.insert(lines, hunk.start + 1, hunk.lines[index])
    end
  end

  return lines
end

local next_group = function(local_patches, remote_patches, local_i, remote_i)
  local local_patch, remote_patch = local_patches[local_i], remote_patches[remote_i]
  local group = { local_patches = {}, remote_patches = {} }

  local overlaps_group = function(hunk)
    return vim.iter(group.local_patches):any(function(other)
      return overlaps(hunk, other)
    end) or vim.iter(group.remote_patches):any(function(other)
      return overlaps(hunk, other)
    end)
  end

  local take = function(patches, index, group_patches)
    local hunk = patches[index]
    if hunk and overlaps_group(hunk) then
      table.insert(group_patches, hunk)
      return true, index + 1
    end
    return false, index
  end

  if local_patch and (not remote_patch or local_patch.start <= remote_patch.start) then
    table.insert(group.local_patches, local_patch)
    local_i = local_i + 1
  else
    table.insert(group.remote_patches, remote_patch)
    remote_i = remote_i + 1
  end

  local expanded = true
  while expanded do
    local local_expanded, remote_expanded
    local_expanded, local_i = take(local_patches, local_i, group.local_patches)
    remote_expanded, remote_i = take(remote_patches, remote_i, group.remote_patches)
    expanded = local_expanded or remote_expanded
  end

  return group, local_i, remote_i
end

local groups = function(local_patches, remote_patches)
  local local_i, remote_i = 1, 1
  local grouped = {}

  while local_patches[local_i] or remote_patches[remote_i] do
    local group
    group, local_i, remote_i = next_group(local_patches, remote_patches, local_i, remote_i)
    table.insert(grouped, group)
  end

  return grouped
end

local row_groups = function(base, local_lines, remote_lines)
  return groups(row_hunks(base, local_lines), row_hunks(base, remote_lines))
end

local pick = function(group, local_wins)
  if #group.remote_patches == 0 or (local_wins and #group.local_patches > 0) then
    return group.local_patches
  end
  return group.remote_patches
end

local resolve = function(grouped, local_wins)
  local patches = {}

  for _, group in ipairs(grouped) do
    vim.list_extend(patches, pick(group, local_wins))
  end

  return patches
end

local sort = function(patches)
  table.sort(patches, function(left, right)
    if left.start ~= right.start then
      return left.start < right.start
    end
    local left_insert, right_insert = left.start == left.finish, right.start == right.finish
    if left_insert ~= right_insert then
      return left_insert
    end
    return (left.slot or 0) < (right.slot or 0)
  end)
end

local bounds = function(group)
  local start, finish = math.huge, 0
  for _, patches in pairs { group.local_patches, group.remote_patches } do
    for _, hunk in ipairs(patches) do
      start = math.min(start, hunk.start)
      finish = math.max(finish, hunk.finish)
    end
  end
  return start, finish
end

local relative = function(patches, start)
  return vim
    .iter(patches)
    :map(function(hunk)
      return {
        start = hunk.start - start,
        finish = hunk.finish - start,
        lines = hunk.lines,
        slot = hunk.slot,
      }
    end)
    :totable()
end

local at_row = function(pos, group, shift)
  local row = unpack(pos)
  if row then
    for _, hunk in ipairs(group.local_patches) do
      local first = hunk.start + shift + 1
      local last = first + #hunk.lines
      if first <= row and row < last then
        return true, shift
      end
      shift = shift + #hunk.lines - (hunk.finish - hunk.start)
    end
  end
  return false, shift
end

local at_base_row = function(pos, group, shift)
  local row = unpack(pos)
  local start, finish = bounds(group)
  return row and start + shift < row and row <= finish + shift
end

local touches = function(pos, local_hunks, hunk)
  local _, col = unpack(pos)
  return hunk.finish > hunk.start
    and (
      hunk.finish == col
      or vim.iter(local_hunks):any(function(other)
        return other.start == other.finish and (hunk.start == other.start or hunk.finish == other.start)
      end)
    )
end

local cursor_hunk = function(linefeed, base, pos, group)
  local start, finish = bounds(group)
  local source = group.local_patches[1] or group.remote_patches[1]
  local before = slice(base, start, finish)
  local local_lines = patch(before, relative(group.local_patches, start))
  local remote_lines = patch(before, relative(group.remote_patches, start))
  local characters = chars(before)
  local local_hunks = diff_hunks(linefeed, characters, chars(local_lines))
  local remote_hunks = vim
    .iter(diff_hunks(linefeed, characters, chars(remote_lines)))
    :filter(function(hunk)
      return not touches(pos, local_hunks, hunk)
    end)
    :totable()
  local character_patches = resolve(groups(local_hunks, remote_hunks), true)
  sort(character_patches)
  local merged = patch(characters, character_patches)
  return {
    start = start,
    finish = finish,
    lines = records(linefeed, table.concat(merged)),
    slot = start == finish and source.slot or nil,
  }
end

local merge_hunks = function(linefeed, base, pos, grouped)
  local merged = {}
  local shift = 0

  for _, group in ipairs(grouped) do
    local cursor_touched
    cursor_touched, shift = at_row(pos, group, shift)
    cursor_touched = cursor_touched or at_base_row(pos, group, shift)
    if cursor_touched then
      table.insert(merged, cursor_hunk(linefeed, base, pos, group))
      pos = {}
    else
      vim.list_extend(merged, pick(group, false))
    end
  end

  return merged
end

---@param eol string?
---@param base string
---@param local_text string
---@param remote_text string
---@param pos ChecktimePosition
---@return string
M.merge = function(eol, base, local_text, remote_text, pos)
  eol = eol or lib.LF
  local base_lines = records(eol, base)
  local local_lines = records(eol, local_text)
  local remote_lines = records(eol, remote_text)
  local grouped = row_groups(base_lines, local_lines, remote_lines)
  local patches = merge_hunks(eol, base_lines, pos, grouped)
  sort(patches)
  return table.concat(patch(base_lines, patches))
end

local window_views = function(buf)
  local views = vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win)
      return vim.api.nvim_win_get_buf(win) == buf
    end)
    :fold({}, function(views, win)
      views[win] = {
        row = (unpack(vim.api.nvim_win_get_cursor(win))),
        topline = vim.api.nvim_win_call(win, function()
          return vim.fn.winsaveview().topline
        end),
      }
      return views
    end)

  return function()
    for win, view in pairs(views) do
      local row = unpack(vim.api.nvim_win_get_cursor(win))
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview { topline = view.topline + row - view.row }
      end)
    end
  end
end

---@param buf integer
---@param text string
---@param mark fun(start: integer, finish: integer)
M.replace = function(buf, text, mark)
  local linefeed = lib.buf_linefeed(buf)
  local restore = window_views(buf)
  local before_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local before = table.concat(before_lines, linefeed)
  if vim.bo[buf].endofline then
    before = before .. linefeed
  end
  local patches = row_hunks(records(linefeed, before), records(linefeed, text))

  vim.api.nvim_buf_call(buf, function()
    for index, hunk in vim.iter(patches):rev():enumerate() do
      if index == #patches then
        vim.cmd [[let &undolevels=&undolevels]]
      else
        vim.cmd.undojoin()
      end

      local lines = buffer_lines(linefeed, table.concat(hunk.lines), not vim.bo[buf].endofline)
      vim.api.nvim_buf_set_lines(buf, hunk.start, hunk.finish, true, lines)
      if #lines > 0 then
        mark(hunk.start, hunk.start + #lines)
      end
    end
  end)
  restore()
end

return M
