local lib = require "goto.lib"

local M = {}

---@param before string
---@param after string
---@return integer[][]
M.indices = function(before, after)
  local result = assert(vim.text.diff(before .. lib.LF, after .. lib.LF, { result_type = "indices" }))
  ---@cast result integer[][]
  return result
end

---@param before string
---@param after string
---@return integer[][]
M.worker = function(before, after)
  return require("goto.fs_reconcile.hunks.diff").indices(before, after)
end

---@class FsReconcileHunk
---@field start integer
---@field finish integer
---@field lines string[]
---@field slot? integer

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
    coroutine.yield(string.sub(text, start))
  end)
end

---@param text string
---@return string[]
M.records = function(text)
  local records = {}
  for record in each_record(text) do
    table.insert(records, record)
  end
  return records
end

---@param lines string[]
---@param start integer
---@param finish integer
---@return string[]
M.slice = function(lines, start, finish)
  return vim.list_slice(lines, start + 1, finish)
end

---@param after_records string[]
---@param indices integer[][]
---@return FsReconcileHunk[]
M.changes = function(after_records, indices)
  return vim
    .iter(indices)
    :map(function(hunk)
      local old_start, old_count, new_start, new_count = unpack(hunk)
      local start = old_start - (old_count == 0 and 0 or 1)
      return {
        start = start,
        finish = start + old_count,
        lines = M.slice(after_records, new_start - 1, new_start + new_count - 1),
      }
    end)
    :totable()
end

return M
