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
    if hunk.finish - hunk.start == #hunk.records then
      for index, record in ipairs(hunk.records) do
        local start = hunk.start + index - 1
        table.insert(patches, { start = start, finish = start + 1, records = { record } })
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
    return patch.finish - patch.start ~= #patch.records
  end)
end

---@param patches FsReconcileHunk[]
---@return boolean
local inserts = function(patches)
  return vim.iter(patches):all(function(patch)
    return patch.start == patch.finish
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
  elseif left.start == left.finish and #right.records == 0 then
    return left.start ~= right.finish
  elseif right.start == right.finish and #left.records == 0 then
    return right.start ~= left.finish
  end
  return true
end

---@param hunk FsReconcileHunk
---@param patches FsReconcileHunk[]
---@return boolean
local conflicts_any = function(hunk, patches)
  return vim.iter(patches):any(function(other)
    return not commutes(hunk, other)
  end)
end

---@param base_records string[]
---@param patches FsReconcileHunk[]
---@param offset integer
---@return string[]
local patch = function(base_records, patches, offset)
  local records = {}
  local cursor = 0

  for _, hunk in ipairs(patches) do
    local start, finish = hunk.start - offset, hunk.finish - offset
    for index = cursor + 1, start do
      table.insert(records, base_records[index])
    end
    vim.list_extend(records, hunk.records)
    cursor = finish
  end

  for index = cursor + 1, #base_records do
    table.insert(records, base_records[index])
  end

  return records
end

---@param group FsReconcileHunkGroup
---@param hunk FsReconcileHunk
---@return boolean
local overlaps_group = function(group, hunk)
  for _, other in ipairs(group.local_patches) do
    if overlaps(hunk, other) then
      return true
    end
  end
  for _, other in ipairs(group.remote_patches) do
    if overlaps(hunk, other) then
      return true
    end
  end
  return false
end

---@param group FsReconcileHunkGroup
---@param patches FsReconcileHunk[]
---@param index integer
---@param group_patches FsReconcileHunk[]
---@return boolean
---@return integer
local take = function(group, patches, index, group_patches)
  local hunk = patches[index]
  if hunk and overlaps_group(group, hunk) then
    table.insert(group_patches, hunk)
    return true, index + 1
  end
  return false, index
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
    local_expanded, local_i = take(group, local_patches, local_i, group.local_patches)
    remote_expanded, remote_i = take(group, remote_patches, remote_i, group.remote_patches)
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

---@param ... FsReconcileHunk[]
---@return integer
---@return integer
local bounds = function(...)
  local start, finish
  for _, patches in ipairs { ... } do
    for _, hunk in ipairs(patches) do
      start = start and math.min(start, hunk.start) or hunk.start
      finish = finish and math.max(finish, hunk.finish) or hunk.finish
    end
  end
  return assert(start), assert(finish)
end

---@param start integer
---@param finish integer
---@param replacement_records string[]
---@return FsReconcileHunk
local replacement = function(start, finish, replacement_records)
  return {
    start = start,
    finish = finish,
    records = replacement_records,
  }
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

---@param left FsReconcileHunk[]
---@param right FsReconcileHunk[]
---@return boolean
local spans_overlap = function(left, right)
  local left_start, left_finish = bounds(left)
  local right_start, right_finish = bounds(right)
  return left_start < right_finish and right_start < left_finish
end

---@param base string
---@param local_record string
---@param remote_record string
---@return string[]
local merge_record = function(base, local_record, remote_record)
  if local_record == remote_record or local_record == base then
    return { remote_record }
  elseif remote_record == base then
    return { local_record }
  end

  local base_text = string.sub(base, 1, -#lib.LF - 1)
  local local_text = string.sub(local_record, 1, -#lib.LF - 1)
  local remote_text = string.sub(remote_record, 1, -#lib.LF - 1)
  local local_patches = atomic_patches(diff.plan_records(character_records(base_text), character_records(local_text)))
  local remote_patches = atomic_patches(diff.plan_records(character_records(base_text), character_records(remote_text)))
  local conflicted = (resizes(local_patches) or resizes(remote_patches))
      and spans_overlap(local_patches, remote_patches)
    or vim.iter(local_patches):any(function(local_patch)
      return conflicts_any(local_patch, remote_patches)
    end)
  if conflicted then
    return { local_record }
  end

  local patches = vim.list_extend(local_patches, remote_patches)
  sort(patches)
  local merged = patch(character_records(base_text), patches, 0)
  return { string.gsub(table.concat(merged), lib.LF, "") .. lib.LF }
end

---@param base_records string[]
---@param group FsReconcileHunkGroup
---@return FsReconcileHunk
local merge_concurrent = function(base_records, group)
  local start, finish = bounds(group.local_patches, group.remote_patches)
  local before = diff.slice(base_records, start, finish)
  if inserts(group.local_patches) and inserts(group.remote_patches) then
    local records = patch(before, group.local_patches, start)
    vim.list_extend(records, patch(before, group.remote_patches, start))
    return replacement(start, finish, records)
  elseif resizes(group.local_patches) or resizes(group.remote_patches) then
    return replacement(start, finish, patch(before, group.local_patches, start))
  end

  local local_records = patch(before, group.local_patches, start)
  local remote_records = patch(before, group.remote_patches, start)
  local records = {}
  for index, record in ipairs(before) do
    vim.list_extend(records, merge_record(record, local_records[index], remote_records[index]))
  end
  return replacement(start, finish, records)
end

---@param base string
---@param local_text string
---@param remote_text string
---@return string
local merge_records = function(base, local_text, remote_text)
  local base_records = diff.records(base)
  local patches = {}

  for group in groups(diff.plan(base, local_text), diff.plan(base, remote_text)) do
    if #group.remote_patches == 0 then
      vim.list_extend(patches, group.local_patches)
    elseif #group.local_patches == 0 then
      vim.list_extend(patches, group.remote_patches)
    else
      table.insert(patches, merge_concurrent(base_records, group))
    end
  end
  sort(patches)
  return table.concat(patch(base_records, patches, 0))
end

---@param base string
---@param local_text string
---@param remote_text string
---@return string
M.merge = function(base, local_text, remote_text)
  if local_text == remote_text then
    return local_text
  elseif local_text == base then
    return remote_text
  elseif remote_text == base then
    return local_text
  end

  local text = merge_records(base, local_text, remote_text)
  return string.sub(text, 1, -#lib.LF - 1)
end

---@param base string
---@param local_text string
---@param remote_text string
---@return string
M.worker = function(base, local_text, remote_text)
  return require("goto.fs_reconcile.hunks.merge").merge(base, local_text, remote_text)
end

return M
