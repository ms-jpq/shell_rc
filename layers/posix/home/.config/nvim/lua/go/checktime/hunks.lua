local lib = require "go.lib"

local M = {}

local slice = function(lines, start, finish)
  if start == finish then
    return {}
  end

  ---@cast start integer
  ---@cast finish integer
  return vim.list_slice(lines, start + 1, finish)
end

M.relocate = function(row, hunks)
  row = row - 1
  local shift = 0

  for _, hunk in ipairs(hunks) do
    local old_count = hunk.finish - hunk.start
    local new_count = #hunk.lines

    if row < hunk.start then
      break
    elseif old_count == 0 then
      shift = shift + new_count
    elseif row >= hunk.finish then
      shift = shift + new_count - old_count
    else
      return hunk.start + shift + math.min(row - hunk.start, math.max(new_count - 1, 0)) + 1
    end
  end

  return row + shift + 1
end

local text = function(lines)
  return #lines == 0 and "" or table.concat(lines, lib.LF) .. lib.LF
end

M.changes = function(before, after)
  return vim
    .iter(vim.text.diff(text(before), text(after), { result_type = "indices" }))
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

local overlaps = function(change, start, finish)
  if change.start == change.finish and start == finish then
    return change.start == start
  elseif change.start == change.finish then
    return start < change.start and change.start < finish
  elseif start == finish then
    return change.start < start and start < change.finish
  end
  return change.start < finish and start < change.finish
end

local apply_changes = function(base, changes, start, finish)
  local merged = slice(base, start, finish)

  for change in vim.iter(changes):rev() do
    local index = change.start - start

    for _ = change.start, change.finish - 1 do
      table.remove(merged, index + 1)
    end
    for line = #change.lines, 1, -1 do
      table.insert(merged, index + 1, change.lines[line])
    end
  end

  return merged
end

local next_group = function(local_changes, remote_changes, local_i, remote_i)
  local local_change = local_changes[local_i]
  local remote_change = remote_changes[remote_i]
  local start =
    math.min(local_change and local_change.start or math.huge, remote_change and remote_change.start or math.huge)
  local group = { start = start, finish = start, local_changes = {}, remote_changes = {} }

  local add = function(change, group_changes)
    group.finish = math.max(group.finish, change.finish)
    table.insert(group_changes, change)
  end

  local take = function(changes, index, group_changes)
    local change = changes[index]
    if change and overlaps(change, group.start, group.finish) then
      add(change, group_changes)
      return index + 1
    end
    return index
  end

  if local_change and local_change.start == start then
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
    return apply_changes(base, group.remote_changes, group.start, group.finish), false
  elseif #group.remote_changes == 0 then
    return apply_changes(base, group.local_changes, group.start, group.finish), false
  end

  local local_lines = apply_changes(base, group.local_changes, group.start, group.finish)
  local remote_lines = apply_changes(base, group.remote_changes, group.start, group.finish)
  local same = vim.deep_equal(local_lines, remote_lines)
  return same and local_lines or remote_lines, not same
end

M.merge = function(base, local_lines, remote_lines)
  local local_changes = M.changes(base, local_lines)
  local remote_changes = M.changes(base, remote_lines)
  local local_i, remote_i = 1, 1
  local row = 0
  local merged = {}
  local conflicted = false

  while local_changes[local_i] or remote_changes[remote_i] do
    local group
    group, local_i, remote_i = next_group(local_changes, remote_changes, local_i, remote_i)
    vim.list_extend(merged, slice(base, row, group.start))
    local lines, conflict = resolve_group(base, group)
    vim.list_extend(merged, lines)
    conflicted = conflicted or conflict
    row = group.finish
  end

  vim.list_extend(merged, slice(base, row, #base))
  return merged, conflicted
end

return M
