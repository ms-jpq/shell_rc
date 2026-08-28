local lib = require "goto.lib"

local M = {}

---@class FsReconcileHunk
---@field start integer
---@field finish integer
---@field records string[]

---@param text string
---@return fun(): string?
local each_record = function(text)
  return coroutine.wrap(function()
    local start = 1
    while true do
      local _, finish = string.find(text, lib.LF, start, true)
      if not finish then
        break
      end
      coroutine.yield(string.sub(text, start, finish))
      start = finish + 1
    end
    if start <= #text then
      coroutine.yield(string.sub(text, start))
    end
  end)
end

---@param text string
---@return string[]
local records = function(text)
  local records = {}
  for record in each_record(text) do
    table.insert(records, record)
  end
  return records
end

---@param text string
---@return string[]
M.records = function(text)
  if text == "" then
    return {}
  end
  return records(text .. lib.LF)
end

---@param lines string[]
---@param start integer
---@param finish integer
---@return string[]
M.slice = function(lines, start, finish)
  return vim.list_slice(lines, start + 1, finish)
end

---@param before_records string[]
---@param after_records string[]
---@return FsReconcileHunk[]
M.plan_records = function(before_records, after_records)
  local indices =
    assert(vim.text.diff(table.concat(before_records), table.concat(after_records), { result_type = "indices" }))
  ---@cast indices integer[][]
  return vim
    .iter(indices)
    :map(function(hunk)
      local old_start, old_count, new_start, new_count = unpack(hunk)
      local start = old_start - (old_count == 0 and 0 or 1)
      return {
        start = start,
        finish = start + old_count,
        records = M.slice(after_records, new_start - 1, new_start + new_count - 1),
      }
    end)
    :totable()
end

---@param before string
---@param after string
---@return FsReconcileHunk[]
M.plan = function(before, after)
  return M.plan_records(M.records(before), M.records(after))
end

---@param before string
---@param after string
---@return FsReconcileHunk[]
M.worker = function(before, after)
  local diff = require "goto.fs_reconcile.hunks.diff"
  return diff.plan(before, after)
end

return M
