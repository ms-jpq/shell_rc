local diff = require "goto.fs_reconcile.hunks.diff"
local lib = require "goto.lib"

local M = {}

---@class FsReconcileHunkGroup
---@field local_patches FsReconcileHunk[]
---@field remote_patches FsReconcileHunk[]

---@param hunks FsReconcileHunk[]
---@return FsReconcileHunk[]
local atomic_patches = function(hunks)
  local patches = {}

  for _, hunk in ipairs(hunks) do
    if hunk.finish - hunk.start == #hunk.lines then
      for index, line in ipairs(hunk.lines) do
        local start = hunk.start + index - 1
        table.insert(patches, { start = start, finish = start + 1, lines = { line } })
      end
    else
      table.insert(patches, hunk)
    end
  end

  return patches
end

---@param patches FsReconcileHunk[]
---@return boolean
local resizes = function(patches)
  return vim.iter(patches):any(function(patch)
    return patch.finish - patch.start ~= #patch.lines
  end)
end

---@param left FsReconcileHunk
---@param right FsReconcileHunk
---@return boolean
local overlaps = function(left, right)
  if left.start == left.finish and right.start == right.finish then
    return left.start == right.start
  elseif left.start == left.finish then
    return right.start < left.start and left.start < right.finish
  elseif right.start == right.finish then
    return left.start < right.start and right.start < left.finish
  end
  return left.start < right.finish and right.start < left.finish
end

---@param left FsReconcileHunk
---@param right FsReconcileHunk
---@return boolean
local commutes = function(left, right)
  if overlaps(left, right) then
    return false
  elseif left.start == left.finish and #right.lines == 0 then
    return left.start ~= right.finish
  elseif right.start == right.finish and #left.lines == 0 then
    return right.start ~= left.finish
  end
  return true
end

---@param hunk FsReconcileHunk
---@param patches FsReconcileHunk[]
---@param active boolean
---@return boolean
local overlaps_any = function(hunk, patches, active)
  return vim.iter(patches):any(function(other)
    if active then
      return not commutes(hunk, other)
    end
    return overlaps(hunk, other)
  end)
end

---@param base string[]
---@param patches FsReconcileHunk[]
---@param offset integer
---@return string[]
local patch = function(base, patches, offset)
  local lines = {}
  local cursor = 0

  for _, hunk in ipairs(patches) do
    local start, finish = hunk.start - offset, hunk.finish - offset
    for index = cursor + 1, start do
      table.insert(lines, base[index])
    end
    vim.list_extend(lines, hunk.lines)
    cursor = finish
  end

  for index = cursor + 1, #base do
    table.insert(lines, base[index])
  end

  return lines
end

---@param local_patches FsReconcileHunk[]
---@param remote_patches FsReconcileHunk[]
---@param local_i integer
---@param remote_i integer
---@return FsReconcileHunkGroup
---@return integer
---@return integer
local next_group = function(local_patches, remote_patches, local_i, remote_i)
  local local_patch, remote_patch = local_patches[local_i], remote_patches[remote_i]
  local group = { local_patches = {}, remote_patches = {} }

  local overlaps_group = function(hunk)
    return overlaps_any(hunk, group.local_patches, false) or overlaps_any(hunk, group.remote_patches, false)
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

---@param local_patches FsReconcileHunk[]
---@param remote_patches FsReconcileHunk[]
---@return fun(): FsReconcileHunkGroup?
local groups = function(local_patches, remote_patches)
  return coroutine.wrap(function()
    local local_i, remote_i = 1, 1
    while local_patches[local_i] or remote_patches[remote_i] do
      local group
      group, local_i, remote_i = next_group(local_patches, remote_patches, local_i, remote_i)
      coroutine.yield(group)
    end
  end)
end

---@param patches FsReconcileHunk[]
local sort = function(patches)
  table.sort(patches, function(left, right)
    if left.start ~= right.start then
      return left.start < right.start
    end
    local left_insert, right_insert = left.start == left.finish, right.start == right.finish
    if left_insert ~= right_insert then
      return left_insert
    end
    return false
  end)
end

---@param group FsReconcileHunkGroup
---@return integer
---@return integer
local bounds = function(group)
  local first = group.local_patches[1] or group.remote_patches[1]
  local start, finish = first.start, first.finish
  local scan = function(patches)
    for _, hunk in ipairs(patches) do
      start = math.min(start, hunk.start)
      finish = math.max(finish, hunk.finish)
    end
  end
  scan(group.local_patches)
  scan(group.remote_patches)
  return start, finish
end

---@param group FsReconcileHunkGroup
---@param replacement_lines string[]
---@return FsReconcileHunk
local replacement = function(group, replacement_lines)
  local start, finish = bounds(group)

  return {
    start = start,
    finish = finish,
    lines = replacement_lines,
  }
end

---@param record string
---@return string
---@return string
local split_record = function(record)
  if vim.endswith(record, lib.LF) then
    return string.sub(record, 1, -#lib.LF - 1), lib.LF
  end
  return record, ""
end

---@param text string
---@return string[]
local character_records = function(text)
  local records = {}
  local start = 1

  for index = 2, #text do
    local byte = string.byte(text, index)
    if byte < 128 or byte >= 192 then
      table.insert(records, string.sub(text, start, index - 1) .. lib.LF)
      start = index
    end
  end
  if start <= #text then
    table.insert(records, string.sub(text, start) .. lib.LF)
  end
  return records
end

---@param before string
---@param after string
---@return FsReconcileHunk[]?
local safe_character_patches = function(before, after)
  local patches = atomic_patches(diff.plan_records(character_records(before), character_records(after)))
  if
    vim.iter(patches):any(function(p)
      return p.start < p.finish and #p.lines > 0 and p.finish - p.start ~= #p.lines
    end)
  then
    return nil
  end
  return patches
end

---@param base string
---@param local_record string
---@param remote_record string
---@param active boolean
---@return string[]
local merge_record = function(base, local_record, remote_record, active)
  if local_record == remote_record or local_record == base then
    return { remote_record }
  elseif remote_record == base then
    return { local_record }
  end

  local base_text = split_record(base)
  local local_text, local_eol = split_record(local_record)
  local remote_text, remote_eol = split_record(remote_record)
  if local_eol ~= remote_eol then
    return { local_record }
  end

  local local_patches = safe_character_patches(base_text, local_text)
  local remote_patches = safe_character_patches(base_text, remote_text)
  if not local_patches or not remote_patches then
    return { local_record }
  end
  local conflicted = vim.iter(local_patches):any(function(local_patch)
    return overlaps_any(local_patch, remote_patches, active)
  end)
  if conflicted then
    return { local_record }
  end

  local patches = vim.list_extend(local_patches, remote_patches)
  sort(patches)
  local merged = patch(character_records(base_text), patches, 0)
  return { string.gsub(table.concat(merged), lib.LF, "") .. local_eol }
end

---@param base string[]
---@param group FsReconcileHunkGroup
---@param cursor_row integer
---@return FsReconcileHunk
local merge_concurrent = function(base, group, cursor_row)
  local start, finish = bounds(group)
  local before = diff.slice(base, start, finish)
  if resizes(group.local_patches) or resizes(group.remote_patches) then
    return replacement(group, patch(before, group.local_patches, start))
  end

  local local_lines = patch(before, group.local_patches, start)
  local remote_lines = patch(before, group.remote_patches, start)
  local lines = {}
  for index, record in ipairs(before) do
    local active = start + index - 1 == cursor_row
    vim.list_extend(lines, merge_record(record, local_lines[index], remote_lines[index], active))
  end
  return replacement(group, lines)
end

---@param base string
---@param local_text string
---@param remote_text string
---@param cursor_row integer
---@return string
local merge = function(base, local_text, remote_text, cursor_row)
  local base_lines = diff.lines(base)
  local patches = {}

  for group in groups(diff.plan(base, local_text), diff.plan(base, remote_text)) do
    if #group.remote_patches == 0 then
      vim.list_extend(patches, group.local_patches)
    elseif #group.local_patches == 0 then
      vim.list_extend(patches, group.remote_patches)
    else
      table.insert(patches, merge_concurrent(base_lines, group, cursor_row))
    end
  end
  sort(patches)
  return table.concat(patch(base_lines, patches, 0))
end

---@param base string
---@param local_text string
---@param remote_text string
---@param cursor_row integer
---@return string
M.merge = function(base, local_text, remote_text, cursor_row)
  if local_text == remote_text then
    return local_text
  elseif local_text == base then
    return remote_text
  elseif remote_text == base then
    return local_text
  end

  local text = merge(base, local_text, remote_text, cursor_row)
  return string.sub(text, 1, -#lib.LF - 1)
end

---@param base string
---@param local_text string
---@param remote_text string
---@param cursor_row integer
---@return string
M.worker = function(base, local_text, remote_text, cursor_row)
  return require("goto.fs_reconcile.hunks.merge").merge(base, local_text, remote_text, cursor_row)
end

return M
