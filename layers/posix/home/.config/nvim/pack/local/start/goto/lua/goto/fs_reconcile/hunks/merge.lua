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
  elseif left.start == left.finish and right.finish - right.start ~= #right.records then
    return left.start ~= right.finish
  elseif right.start == right.finish and left.finish - left.start ~= #left.records then
    return right.start ~= left.finish
  end
  return true
end

---@param left FsReconcileHunk
---@param right FsReconcileHunk
---@return boolean
local conflicts = function(left, right)
  return not commutes(left, right)
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
---@param related fun(left: FsReconcileHunk, right: FsReconcileHunk): boolean
---@return boolean
local related_group = function(group, hunk, related)
  for _, other in ipairs(group.local_patches) do
    if related(hunk, other) then
      return true
    end
  end
  for _, other in ipairs(group.remote_patches) do
    if related(hunk, other) then
      return true
    end
  end
  return false
end

---@param left FsReconcileHunk
---@param right FsReconcileHunk
---@return boolean
local precedes = function(left, right)
  if left.start ~= right.start then
    return left.start < right.start
  end
  local left_insert, right_insert = left.start == left.finish, right.start == right.finish
  return left_insert and not right_insert
end

---@param patches FsReconcileHunk[]
local sort = function(patches)
  table.sort(patches, precedes)
end

---@param local_patches FsReconcileHunk[]
---@param remote_patches FsReconcileHunk[]
---@param related fun(left: FsReconcileHunk, right: FsReconcileHunk): boolean
---@return fun(): FsReconcileHunkGroup?
local groups = function(local_patches, remote_patches, related)
  return coroutine.wrap(function()
    local pending = {}
    for _, hunk in ipairs(local_patches) do
      table.insert(pending, { hunk = hunk, local_patch = true })
    end
    for _, hunk in ipairs(remote_patches) do
      table.insert(pending, { hunk = hunk, local_patch = false })
    end
    table.sort(pending, function(left, right)
      return precedes(left.hunk, right.hunk)
    end)

    while #pending > 0 do
      local first = table.remove(pending, 1)
      local group = { local_patches = {}, remote_patches = {} }
      table.insert(first.local_patch and group.local_patches or group.remote_patches, first.hunk)

      while pending[1] and related_group(group, pending[1].hunk, related) do
        local item = table.remove(pending, 1)
        table.insert(item.local_patch and group.local_patches or group.remote_patches, item.hunk)
      end
      coroutine.yield(group)
    end
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

---@param group FsReconcileHunkGroup
---@return FsReconcileHunk
local merge_insertions = function(group)
  local local_records = {}
  local remote_records = {}
  for _, hunk in ipairs(group.local_patches) do
    vim.list_extend(local_records, hunk.records)
  end
  for _, hunk in ipairs(group.remote_patches) do
    vim.list_extend(remote_records, hunk.records)
  end
  if not vim.deep_equal(local_records, remote_records) then
    vim.list_extend(local_records, remote_records)
  end
  local start, finish = bounds(group.local_patches, group.remote_patches)
  return replacement(start, finish, local_records)
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

---@param base string
---@param local_text string
---@param remote_text string
---@return string
local merge_characters = function(base, local_text, remote_text)
  local base_records = character_records(base)
  local local_patches = atomic_patches(diff.plan_records(base_records, character_records(local_text)))
  local remote_patches = atomic_patches(diff.plan_records(base_records, character_records(remote_text)))
  local patches = {}

  for group in groups(local_patches, remote_patches, conflicts) do
    if #group.remote_patches == 0 then
      vim.list_extend(patches, group.local_patches)
    elseif #group.local_patches == 0 then
      vim.list_extend(patches, group.remote_patches)
    elseif inserts(group.local_patches) and inserts(group.remote_patches) then
      table.insert(patches, merge_insertions(group))
    else
      vim.list_extend(patches, group.local_patches)
    end
  end
  sort(patches)
  return string.gsub(table.concat(patch(base_records, patches, 0)), lib.LF, "")
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
  return { merge_characters(base_text, local_text, remote_text) .. lib.LF }
end

---@param base_records string[]
---@param group FsReconcileHunkGroup
---@return FsReconcileHunk
local merge_concurrent = function(base_records, group)
  local start, finish = bounds(group.local_patches, group.remote_patches)
  local before = diff.slice(base_records, start, finish)
  if inserts(group.local_patches) and inserts(group.remote_patches) then
    return merge_insertions(group)
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
  local local_patches = atomic_patches(diff.plan(base, local_text))
  local remote_patches = atomic_patches(diff.plan(base, remote_text))
  local patches = {}

  for group in groups(local_patches, remote_patches, overlaps) do
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
