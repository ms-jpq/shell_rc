local lib = require "go.lib"

local M = {}

local chars = function(linefeed, lines)
  return vim.fn.split(table.concat(lines, linefeed), [[\zs]])
end

local text_lines = function(linefeed, characters)
  local text = table.concat(characters)
  return text == "" and {} or vim.split(text, linefeed, { plain = true })
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

local text = function(linefeed, lines)
  return #lines == 0 and "" or table.concat(lines, linefeed) .. linefeed
end

local diff = function(linefeed, before, after)
  return vim
    .iter(vim.text.diff(text(linefeed, before), text(linefeed, after), { result_type = "indices" }))
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

local diff_hunks = function(linefeed, before, after, atomic)
  local changes = diff(linefeed, before, after)
  if atomic then
    return vim.iter(changes):map(split):flatten():totable()
  end
  return changes
end

local row_hunks = function(linefeed, before, after)
  return diff_hunks(linefeed, before, after, true)
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

local row_groups = function(linefeed, base, local_lines, remote_lines)
  return groups(row_hunks(linefeed, base, local_lines), row_hunks(linefeed, base, remote_lines))
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

local at_row = function(group, row, shift)
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

local touches = function(hunk, local_hunks)
  return hunk.finish > hunk.start
    and vim.iter(local_hunks):any(function(other)
      return other.start == other.finish and (hunk.start == other.start or hunk.finish == other.start)
    end)
end

local cursor_hunk = function(linefeed, base, group)
  local start, finish = bounds(group)
  local before = slice(base, start, finish)
  local local_lines = patch(before, relative(group.local_patches, start))
  local remote_lines = patch(before, relative(group.remote_patches, start))
  local characters = chars(linefeed, before)
  local local_hunks = diff_hunks(linefeed, characters, chars(linefeed, local_lines))
  local remote_hunks = vim
    .iter(diff_hunks(linefeed, characters, chars(linefeed, remote_lines)))
    :filter(function(hunk)
      return not touches(hunk, local_hunks)
    end)
    :totable()
  local character_patches = resolve(groups(local_hunks, remote_hunks), true)
  sort(character_patches)
  local merged = patch(characters, character_patches)
  return { start = start, finish = finish, lines = text_lines(linefeed, merged) }
end

local merge_hunks = function(linefeed, base, grouped, row)
  local merged = {}
  local shift = 0

  for _, group in ipairs(grouped) do
    local cursor_touched
    cursor_touched, shift = at_row(group, row, shift)
    if cursor_touched then
      row = nil
      table.insert(merged, cursor_hunk(linefeed, base, group))
    else
      vim.list_extend(merged, pick(group, false))
    end
  end

  return merged
end

M.merge = function(eol, base, local_lines, remote_lines, pos)
  eol = eol or lib.LF
  local row = unpack(pos)
  local grouped = row_groups(eol, base, local_lines, remote_lines)
  local patches = merge_hunks(eol, base, grouped, row)
  sort(patches)
  return patch(base, patches)
end

M.replace = function(buf, lines, mark)
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local patches = row_hunks(lib.buf_linefeed(buf), before, lines)

  vim.api.nvim_buf_call(buf, function()
    for index, hunk in vim.iter(patches):rev():enumerate() do
      if index == #patches then
        vim.cmd [[let &undolevels=&undolevels]]
      else
        vim.cmd.undojoin()
      end
      vim.api.nvim_buf_set_lines(buf, hunk.start, hunk.finish, true, hunk.lines)
      if #hunk.lines > 0 then
        mark(hunk.start, hunk.start + #hunk.lines)
      end
    end
  end)
end

return M
