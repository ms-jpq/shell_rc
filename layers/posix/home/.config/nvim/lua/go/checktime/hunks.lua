local lib = require "go.lib"

local M = {}

local slice = function(lines, first, last)
  if first > last then
    return {}
  end

  ---@cast first integer
  ---@cast last integer
  return vim.list_slice(lines, first, last)
end

M.relocate = function(row, hunks)
  local shift = 0

  for _, hunk in ipairs(hunks) do
    local old_count = hunk.finish - hunk.start
    local new_count = #hunk.lines

    if row < hunk.first then
      break
    elseif old_count == 0 then
      shift = shift + new_count
    elseif row >= hunk.last then
      shift = shift + new_count - old_count
    else
      local offset = math.min(row - hunk.first, math.max(new_count - 1, 0))
      return hunk.first + shift + offset
    end
  end

  return row + shift
end

local text = function(lines)
  return #lines == 0 and "" or table.concat(lines, lib.LF) .. lib.LF
end

M.changes = function(before, after)
  return vim
    .iter(vim.text.diff(text(before), text(after), { result_type = "indices" }))
    :map(function(hunk)
      local old_start, old_count, new_start, new_count = unpack(hunk)
      local first = old_start + (old_count == 0 and 1 or 0)
      local start = first - 1
      return {
        first = first,
        last = first + old_count,
        start = start,
        finish = start + old_count,
        lines = slice(after, new_start, new_start + new_count - 1),
      }
    end)
    :totable()
end

local overlaps = function(change, first, last)
  if change.first == change.last and first == last then
    return change.first == first
  elseif change.first == change.last then
    return first < change.first and change.first < last
  elseif first == last then
    return change.first < first and first < change.last
  end
  return change.first < last and first < change.last
end

local apply_changes = function(base, changes, first, last)
  local merged = slice(base, first, last - 1)

  for change in vim.iter(changes):rev() do
    local start = change.first - first

    for _ = change.first, change.last - 1 do
      table.remove(merged, start + 1)
    end
    for index = #change.lines, 1, -1 do
      table.insert(merged, start + 1, change.lines[index])
    end
  end

  return merged
end

local next_group = function(local_changes, remote_changes, local_i, remote_i)
  local local_change = local_changes[local_i]
  local remote_change = remote_changes[remote_i]
  local first =
    math.min(local_change and local_change.first or math.huge, remote_change and remote_change.first or math.huge)
  local group = { first = first, last = first, local_changes = {}, remote_changes = {} }

  local add = function(change, group_changes)
    group.last = math.max(group.last, change.last)
    table.insert(group_changes, change)
  end

  local take = function(changes, index, group_changes)
    local change = changes[index]
    if change and overlaps(change, group.first, group.last) then
      add(change, group_changes)
      return index + 1
    end
    return index
  end

  if local_change and local_change.first == first then
    add(local_change, group.local_changes)
    local_i = local_i + 1
  else
    add(remote_change, group.remote_changes)
    remote_i = remote_i + 1
  end

  while true do
    local before_local, before_remote = local_i, remote_i
    local_i = take(local_changes, local_i, group.local_changes)
    remote_i = take(remote_changes, remote_i, group.remote_changes)
    if local_i == before_local and remote_i == before_remote then
      return group, local_i, remote_i
    end
  end
end

local resolve_group = function(base, group)
  if #group.local_changes == 0 then
    return apply_changes(base, group.remote_changes, group.first, group.last), false
  elseif #group.remote_changes == 0 then
    return apply_changes(base, group.local_changes, group.first, group.last), false
  end

  local local_lines = apply_changes(base, group.local_changes, group.first, group.last)
  local remote_lines = apply_changes(base, group.remote_changes, group.first, group.last)
  local same = vim.deep_equal(local_lines, remote_lines)
  return same and local_lines or remote_lines, not same
end

M.merge = function(base, local_lines, remote_lines)
  local local_changes = M.changes(base, local_lines)
  local remote_changes = M.changes(base, remote_lines)
  local local_i, remote_i = 1, 1
  local row = 1
  local merged = {}
  local conflicted = false

  while local_changes[local_i] or remote_changes[remote_i] do
    local group
    group, local_i, remote_i = next_group(local_changes, remote_changes, local_i, remote_i)
    vim.list_extend(merged, slice(base, row, group.first - 1))
    local lines, conflict = resolve_group(base, group)
    vim.list_extend(merged, lines)
    conflicted = conflicted or conflict
    row = group.last
  end

  vim.list_extend(merged, slice(base, row, #base))
  return merged, conflicted
end

return M
