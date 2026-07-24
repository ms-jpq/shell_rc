local lib = require "go.lib"

local M = {}

local chars = function(lines, linefeed)
  return vim.fn.split(table.concat(lines, linefeed), [[\zs]])
end

local text_lines = function(characters, linefeed)
  local text = table.concat(characters)
  return text == "" and {} or vim.split(text, linefeed, { plain = true })
end

local split = function(patch)
  local old_count = patch.finish - patch.start
  local count = math.max(old_count, #patch.lines)
  local patches = {}

  for index = 0, count - 1 do
    local start = patch.start + math.min(index, old_count)
    table.insert(patches, {
      start = start,
      finish = start + (index < old_count and 1 or 0),
      lines = index < #patch.lines and { patch.lines[index + 1] } or {},
      slot = index < old_count and nil or index - old_count,
    })
  end

  return patches
end

local slice = function(lines, start, finish)
  return vim.list_slice(lines, math.floor(start + 1), math.floor(finish))
end

local text = function(lines, linefeed)
  return #lines == 0 and "" or table.concat(lines, linefeed) .. linefeed
end

local diff = function(before, after, linefeed)
  return vim
    .iter(vim.text.diff(text(before, linefeed), text(after, linefeed), { result_type = "indices" }))
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

local hunks = function(before, after, linefeed, atomic)
  local changes = diff(before, after, linefeed)
  if atomic then
    return vim.iter(changes):map(split):flatten():totable()
  end
  return changes
end

local row_hunks = function(before, after, linefeed)
  return hunks(before, after, linefeed, true)
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

local apply = function(base, patches)
  local lines = slice(base, 0, #base)

  for patch in vim.iter(patches):rev() do
    for _ = patch.start, patch.finish - 1 do
      table.remove(lines, patch.start + 1)
    end
    for index = #patch.lines, 1, -1 do
      table.insert(lines, patch.start + 1, patch.lines[index])
    end
  end

  return lines
end

local next_group = function(local_patches, remote_patches, local_i, remote_i)
  local local_patch, remote_patch = local_patches[local_i], remote_patches[remote_i]
  local group = { local_patches = {}, remote_patches = {} }

  local overlaps_group = function(patch)
    return vim.iter(group.local_patches):any(function(other)
      return overlaps(patch, other)
    end) or vim.iter(group.remote_patches):any(function(other)
      return overlaps(patch, other)
    end)
  end

  local take = function(patches, index, group_patches)
    local patch = patches[index]
    if patch and overlaps_group(patch) then
      table.insert(group_patches, patch)
      return index + 1
    end
    return index
  end

  if local_patch and (not remote_patch or local_patch.start <= remote_patch.start) then
    table.insert(group.local_patches, local_patch)
    local_i = local_i + 1
  else
    table.insert(group.remote_patches, remote_patch)
    remote_i = remote_i + 1
  end

  while true do
    local before_local, before_remote = local_i, remote_i
    local_i = take(local_patches, local_i, group.local_patches)
    remote_i = take(remote_patches, remote_i, group.remote_patches)
    if local_i == before_local and remote_i == before_remote then
      return group, local_i, remote_i
    end
  end
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

local row_groups = function(base, local_lines, remote_lines, linefeed)
  return groups(row_hunks(base, local_lines, linefeed), row_hunks(base, remote_lines, linefeed))
end

local resolve = function(grouped, local_wins)
  local patches = {}

  for _, group in ipairs(grouped) do
    local selected = group.remote_patches
    if #selected == 0 or (local_wins and #group.local_patches > 0) then
      selected = group.local_patches
    end
    vim.list_extend(patches, selected)
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
    for _, patch in ipairs(patches) do
      start = math.min(start, patch.start)
      finish = math.max(finish, patch.finish)
    end
  end
  return start, finish
end

local relative = function(patches, start)
  return vim
    .iter(patches)
    :map(function(patch)
      return {
        start = patch.start - start,
        finish = patch.finish - start,
        lines = patch.lines,
        slot = patch.slot,
      }
    end)
    :totable()
end

local char_merge = function(base, group, linefeed)
  local start, finish = bounds(group)
  local before = slice(base, start, finish)
  local local_lines = apply(before, relative(group.local_patches, start))
  local remote_lines = apply(before, relative(group.remote_patches, start))
  local characters = chars(before, linefeed)
  local local_characters = chars(local_lines, linefeed)
  local remote_characters = chars(remote_lines, linefeed)
  local patches =
    resolve(groups(hunks(characters, local_characters, linefeed), hunks(characters, remote_characters, linefeed)), true)
  sort(patches)
  local merged = apply(characters, patches)
  return { { start = start, finish = finish, lines = text_lines(merged, linefeed) } }
end

local at_row = function(group, row, shift)
  if row then
    for _, patch in ipairs(group.local_patches) do
      local first = patch.start + shift + 1
      local last = first + #patch.lines
      if first <= row and row < last then
        return true, shift
      end
      shift = shift + #patch.lines - (patch.finish - patch.start)
    end
  end
  return false, shift
end

local merge_patches = function(base, grouped, row, linefeed)
  local patches = {}
  local shift = 0

  for _, group in ipairs(grouped) do
    local at_cursor
    at_cursor, shift = at_row(group, row, shift)
    if at_cursor then
      row = nil
      vim.list_extend(patches, char_merge(base, group, linefeed))
    else
      vim.list_extend(patches, resolve({ group }, false))
    end
  end

  return patches
end

M.merge = function(base, local_lines, remote_lines, pos, eol)
  local row = unpack(pos)
  eol = eol or lib.LF
  local grouped = row_groups(base, local_lines, remote_lines, eol)
  local merged = merge_patches(base, grouped, row, eol)
  sort(merged)
  return apply(base, merged)
end

M.replace = function(buf, lines, mark)
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local patches = row_hunks(before, lines, lib.buf_linefeed(buf))

  vim.api.nvim_buf_call(buf, function()
    for index, patch in vim.iter(patches):rev():enumerate() do
      if index == #patches then
        vim.cmd [[let &undolevels=&undolevels]]
      else
        vim.cmd.undojoin()
      end
      vim.api.nvim_buf_set_lines(buf, patch.start, patch.finish, true, patch.lines)
      if #patch.lines > 0 then
        mark(patch.start, patch.start + #patch.lines)
      end
    end
  end)
end

return M
