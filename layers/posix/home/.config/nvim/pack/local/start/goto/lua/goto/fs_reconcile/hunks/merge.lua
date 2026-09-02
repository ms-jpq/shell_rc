local diff = require "goto.fs_reconcile.hunks.diff"
local lib = require "goto.lib"

local M = {}

---@class FsReconcileHunkComponent
---@field local_patches FsReconcileHunk[]
---@field remote_patches FsReconcileHunk[]

---@param hunk FsReconcileHunk
---@return boolean
local insertion = function(hunk)
  return hunk.start == hunk.finish
end

---@param hunk FsReconcileHunk
---@return boolean
local resize = function(hunk)
  return hunk.finish - hunk.start ~= #hunk.records
end

---@param hunks FsReconcileHunk[]
---@return FsReconcileHunk[]
local atomize = function(hunks)
  local patches = {}

  for _, hunk in ipairs(hunks) do
    if not resize(hunk) then
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

---@param base_records string[]
---@param target_records string[]
---@return FsReconcileHunk[]
local changes = function(base_records, target_records)
  return atomize(diff.plan_records(base_records, target_records))
end

---@param left FsReconcileHunk
---@param right FsReconcileHunk
---@return boolean
local overlaps = function(left, right)
  if insertion(left) and insertion(right) then
    return left.start == right.start
  elseif insertion(left) then
    return right.start < left.start and left.start < right.finish
  elseif insertion(right) then
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
  elseif insertion(left) and resize(right) then
    return left.start ~= right.finish
  elseif insertion(right) and resize(left) then
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

---@param component FsReconcileHunkComponent
---@param hunk FsReconcileHunk
---@param local_patch boolean
---@param related fun(left: FsReconcileHunk, right: FsReconcileHunk): boolean
---@return boolean
local joins = function(component, hunk, local_patch, related)
  local others = local_patch and component.remote_patches or component.local_patches
  for _, other in ipairs(others) do
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
  local left_insert, right_insert = insertion(left), insertion(right)
  return left_insert and not right_insert
end

---@param patches FsReconcileHunk[]
local sort = function(patches)
  table.sort(patches, precedes)
end

---@param local_patches FsReconcileHunk[]
---@param remote_patches FsReconcileHunk[]
---@param related fun(left: FsReconcileHunk, right: FsReconcileHunk): boolean
---@return fun(): FsReconcileHunkComponent?
local components = function(local_patches, remote_patches, related)
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

    local index = 1
    while pending[index] do
      local first = pending[index]
      pending[index] = nil
      index = index + 1
      local component = { local_patches = {}, remote_patches = {} }
      table.insert(first.local_patch and component.local_patches or component.remote_patches, first.hunk)

      while pending[index] and joins(component, pending[index].hunk, pending[index].local_patch, related) do
        local item = pending[index]
        pending[index] = nil
        index = index + 1
        table.insert(item.local_patch and component.local_patches or component.remote_patches, item.hunk)
      end
      coroutine.yield(component)
    end
  end)
end

---@param component FsReconcileHunkComponent
---@return integer
---@return integer
local bounds = function(component)
  local start, finish
  for _, patches in ipairs { component.local_patches, component.remote_patches } do
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

---@param component FsReconcileHunkComponent
---@return boolean
local pure_insertions = function(component)
  return vim.iter(component.local_patches):all(insertion) and vim.iter(component.remote_patches):all(insertion)
end

---@param component FsReconcileHunkComponent
---@return boolean
local structural = function(component)
  return vim.iter(component.local_patches):any(resize) or vim.iter(component.remote_patches):any(resize)
end

---@param component FsReconcileHunkComponent
---@return FsReconcileHunk
local merge_insertions = function(component)
  local local_records = {}
  local remote_records = {}
  for _, hunk in ipairs(component.local_patches) do
    vim.list_extend(local_records, hunk.records)
  end
  for _, hunk in ipairs(component.remote_patches) do
    vim.list_extend(remote_records, hunk.records)
  end
  if not vim.deep_equal(local_records, remote_records) then
    vim.list_extend(local_records, remote_records)
  end
  local start, finish = bounds(component)
  return replacement(start, finish, local_records)
end

---@param base_records string[]
---@param patches FsReconcileHunk[]
---@param offset integer
---@return string[]
local apply = function(base_records, patches, offset)
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

---@param base_records string[]
---@param local_records string[]
---@param remote_records string[]
---@param related fun(left: FsReconcileHunk, right: FsReconcileHunk): boolean
---@param resolve fun(component: FsReconcileHunkComponent, base_records: string[]): FsReconcileHunk[]
---@return string[]
local reconcile = function(base_records, local_records, remote_records, related, resolve)
  local patches = {}
  for component in components(changes(base_records, local_records), changes(base_records, remote_records), related) do
    if #component.remote_patches == 0 then
      vim.list_extend(patches, component.local_patches)
    elseif #component.local_patches == 0 then
      vim.list_extend(patches, component.remote_patches)
    elseif pure_insertions(component) then
      table.insert(patches, merge_insertions(component))
    else
      vim.list_extend(patches, resolve(component, base_records))
    end
  end
  sort(patches)
  return apply(base_records, patches, 0)
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

---@param component FsReconcileHunkComponent
---@return FsReconcileHunk[]
local local_authority = function(component)
  return component.local_patches
end

---@param base string
---@param local_text string
---@param remote_text string
---@return string
local merge_characters = function(base, local_text, remote_text)
  local local_records = character_records(local_text)
  local remote_records = character_records(remote_text)
  local base_records = character_records(base)

  local records = reconcile(base_records, local_records, remote_records, conflicts, local_authority)
  return (string.gsub(table.concat(records), lib.LF, ""))
end

---@param base string
---@param local_record string
---@param remote_record string
---@return string[]
local merge_record = function(base, local_record, remote_record)
  local base_text = string.sub(base, 1, -#lib.LF - 1)
  local local_text = string.sub(local_record, 1, -#lib.LF - 1)
  local remote_text = string.sub(remote_record, 1, -#lib.LF - 1)
  return { merge_characters(base_text, local_text, remote_text) .. lib.LF }
end

---@param component FsReconcileHunkComponent
---@param base_records string[]
---@return FsReconcileHunk[]
local resolve_rows = function(component, base_records)
  local start, finish = bounds(component)
  local before = diff.slice(base_records, start, finish)
  if structural(component) then
    return { replacement(start, finish, apply(before, component.local_patches, start)) }
  end

  local local_records = apply(before, component.local_patches, start)
  local remote_records = apply(before, component.remote_patches, start)
  local records = {}
  for index, record in ipairs(before) do
    vim.list_extend(records, merge_record(record, local_records[index], remote_records[index]))
  end
  return { replacement(start, finish, records) }
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

  local base_records = diff.records(base)
  local text =
    table.concat(reconcile(base_records, diff.records(local_text), diff.records(remote_text), overlaps, resolve_rows))
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
