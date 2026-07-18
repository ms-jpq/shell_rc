local lib = require "go.lib"

local M = {}

local slice = function(lines, start, finish)
  if start == finish then
    return {}
  end
  return vim.list_slice(lines, start + 1, finish)
end

local text = function(lines)
  return #lines == 0 and "" or table.concat(lines, lib.LF) .. lib.LF
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

local diff = function(before, after)
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
    :map(split)
    :flatten()
    :totable()
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

  local add = function(patch, patches)
    table.insert(patches, patch)
  end

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
      add(patch, group_patches)
      return index + 1
    end
    return index
  end

  if local_patch and (not remote_patch or local_patch.start <= remote_patch.start) then
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

local merge = function(local_patches, remote_patches, protected)
  local local_i, remote_i = 1, 1
  local patches = {}

  while local_patches[local_i] or remote_patches[remote_i] do
    local group
    group, local_i, remote_i = next_group(local_patches, remote_patches, local_i, remote_i)
    local local_wins = #group.remote_patches == 0
      or vim.iter(group.local_patches):any(function(patch)
        return protected[patch]
      end)
    vim.list_extend(patches, local_wins and group.local_patches or group.remote_patches)
  end

  return patches
end

local protect_cursor_line = function(patches, row)
  local protected = {}
  local shift = 0

  for _, patch in ipairs(patches) do
    local first = patch.start + shift + 1
    local last = first + #patch.lines
    if row and first <= row and row < last then
      protected[patch] = true
    end
    shift = shift + #patch.lines - (patch.finish - patch.start)
  end

  return protected
end

M.merge = function(base, local_lines, remote_lines, cursor_row)
  local local_patches = diff(base, local_lines)
  local remote_patches = diff(base, remote_lines)
  local protected = protect_cursor_line(local_patches, cursor_row)
  local merged = merge(local_patches, remote_patches, protected)
  return apply(base, merged)
end

M.replace = function(buf, lines)
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local patches = diff(before, lines)

  vim.api.nvim_buf_call(buf, function()
    for index, patch in vim.iter(patches):rev():enumerate() do
      if index == #patches then
        vim.cmd [[let &undolevels=&undolevels]]
      else
        vim.cmd.undojoin()
      end
      vim.api.nvim_buf_set_lines(buf, patch.start, patch.finish, true, patch.lines)
    end
  end)
end

return M
