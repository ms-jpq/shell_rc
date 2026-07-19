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

local overlaps_cursor_prefix = function(patches, before_cursor)
  if before_cursor == "" then
    return false
  end

  return vim.iter(patches):any(function(patch)
    return vim.iter(patch.lines):any(function(line)
      return vim.startswith(line, before_cursor) or (line ~= "" and vim.startswith(before_cursor, line))
    end)
  end)
end

local append_remote = function(local_patches, remote_patches, before_cursor)
  if overlaps_cursor_prefix(remote_patches, before_cursor) then
    return {}
  end

  local start, lines = 0, {}
  for _, patch in ipairs(local_patches) do
    start = math.max(start, patch.finish)
  end
  for _, patch in ipairs(remote_patches) do
    vim.list_extend(lines, patch.lines)
  end
  if #lines == 0 then
    return {}
  end
  return { { start = start, finish = start, lines = lines } }
end

local groups = function(local_patches, remote_patches)
  local local_i, remote_i = 1, 1
  local groups = {}

  while local_patches[local_i] or remote_patches[remote_i] do
    local group
    group, local_i, remote_i = next_group(local_patches, remote_patches, local_i, remote_i)
    table.insert(groups, group)
  end

  return groups
end

local protect_cursor_line = function(groups, local_lines, row, col)
  if not row then
    return {}
  end

  local protected = {}
  local shift = 0
  local before_cursor = string.sub(local_lines[row], 1, col)

  for _, group in ipairs(groups) do
    for _, patch in ipairs(group.local_patches) do
      local first = patch.start + shift + 1
      local last = first + #patch.lines
      if first <= row and row < last then
        local patches = vim.list_extend({}, group.local_patches)
        vim.list_extend(patches, append_remote(group.local_patches, group.remote_patches, before_cursor))
        protected[group] = patches
        return protected
      end
      shift = shift + #patch.lines - (patch.finish - patch.start)
    end
  end

  return protected
end

local merge = function(groups, protected)
  local patches = {}

  for _, group in ipairs(groups) do
    local normal = #group.remote_patches == 0 and group.local_patches or group.remote_patches
    vim.list_extend(patches, protected[group] or normal)
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

M.merge = function(base, local_lines, remote_lines, pos)
  local row, col = unpack(pos)
  local local_patches = diff(base, local_lines)
  local remote_patches = diff(base, remote_lines)
  local grouped = groups(local_patches, remote_patches)
  local protected = protect_cursor_line(grouped, local_lines, row, col)
  local merged = merge(grouped, protected)
  sort(merged)
  return apply(base, merged)
end

M.replace = function(buf, lines, mark)
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
      if #patch.lines > 0 then
        mark(patch.start, patch.start + #patch.lines)
      end
    end
  end)
end

return M
