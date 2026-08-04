local lib = require "goto.lib"

local M = {}

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

local row_patches = function(changes)
  return vim.iter(changes):map(split):flatten():totable()
end

local diff_hunks = function(separator, before, after, atomic)
  local changes = diff(separator, before, after)
  if atomic then
    return row_patches(changes)
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

local span = function(base, text)
  local start = 1
  while start <= #base and base[start] == text[start] do
    start = start + 1
  end

  local finish = #base
  while finish >= start and base[finish] == text[#text - (#base - finish)] do
    finish = finish - 1
  end

  return { start = start - 1, finish = finish, slot = 0 }
end

local touches = function(local_hunks, hunk)
  return hunk.finish > hunk.start
    and vim.iter(local_hunks):any(function(other)
      return other.start == other.finish and (hunk.start == other.start or hunk.finish == other.start)
    end)
end

local character_hunk = function(linefeed, base, group)
  local start, finish = bounds(group)
  local source = group.local_patches[1] or group.remote_patches[1]
  local before = slice(base, start, finish)
  local local_lines = patch(before, relative(group.local_patches, start))
  local remote_lines = patch(before, relative(group.remote_patches, start))
  local characters = chars(before)
  local local_characters = chars(local_lines)
  local remote_characters = chars(remote_lines)

  if overlaps(span(characters, local_characters), span(characters, remote_characters)) then
    return {
      start = start,
      finish = finish,
      lines = local_lines,
      slot = start == finish and source.slot or nil,
    }
  end

  local local_hunks = diff_hunks(linefeed, characters, local_characters)
  local remote_hunks = vim
    .iter(diff_hunks(linefeed, characters, remote_characters))
    :filter(function(hunk)
      return not touches(local_hunks, hunk)
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

local merge_hunks = function(linefeed, base, grouped)
  local merged = {}

  for _, group in ipairs(grouped) do
    if #group.local_patches > 0 and #group.remote_patches > 0 then
      table.insert(merged, character_hunk(linefeed, base, group))
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
---@return string
M.merge = function(eol, base, local_text, remote_text)
  eol = eol or lib.LF
  local base_lines = records(eol, base)
  local local_lines = records(eol, local_text)
  local remote_lines = records(eol, remote_text)
  local grouped = row_groups(base_lines, local_lines, remote_lines)
  local patches = merge_hunks(eol, base_lines, grouped)
  sort(patches)
  return table.concat(patch(base_lines, patches))
end

local transform = function(patches, row)
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

local window_views = function(buf, patches)
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
      local row, col = unpack(vim.api.nvim_win_get_cursor(win))
      row = transform(patches, view.row)
      local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, true)[1]
      vim.api.nvim_win_call(win, function()
        vim.api.nvim_win_set_cursor(win, { row, math.min(col, #line) })
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
  local before_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local before = table.concat(before_lines, linefeed)
  if vim.bo[buf].endofline then
    before = before .. linefeed
  end
  local changes = diff("", records(linefeed, before), records(linefeed, text))
  local patches = row_patches(changes)
  local restore = window_views(buf, changes)

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
