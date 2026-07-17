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

M.transform = function(hunks, row)
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

M.diff = function(before, after)
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

M.apply = function(base, patches)
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
  local start =
    math.min(local_patch and local_patch.start or math.huge, remote_patch and remote_patch.start or math.huge)
  local group = { start = start, finish = start, local_patches = {}, remote_patches = {} }

  local add = function(patch, patches)
    group.finish = math.max(group.finish, patch.finish)
    table.insert(patches, patch)
  end

  local take = function(patches, index, group_patches)
    local patch = patches[index]
    if patch and overlaps(patch, group.start, group.finish) then
      add(patch, group_patches)
      return index + 1
    end
    return index
  end

  if local_patch and local_patch.start == start then
    add(local_patch, group.local_patches)
    local_i = local_i + 1
  else
    add(remote_patch, group.remote_patches)
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

M.merge = function(local_patches, remote_patches)
  local local_i, remote_i = 1, 1
  local patches = {}

  while local_patches[local_i] or remote_patches[remote_i] do
    local group
    group, local_i, remote_i = next_group(local_patches, remote_patches, local_i, remote_i)
    vim.list_extend(patches, #group.local_patches > 0 and group.local_patches or group.remote_patches)
  end

  return patches
end

M.three_way = function(base, local_lines, remote_lines)
  local local_patches = M.diff(base, local_lines)
  local remote_patches = M.diff(base, remote_lines)
  return M.apply(base, M.merge(local_patches, remote_patches))
end

return M
