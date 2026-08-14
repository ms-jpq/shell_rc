local async = require "goto.async"

local M = {}

---@class FsReconcileHunk
---@field start integer
---@field finish integer
---@field lines string[]
---@field slot? integer

local each_record = function(linefeed, text)
  return coroutine.wrap(function()
    local start = 1
    while true do
      local _, finish = string.find(text, linefeed, start, true)
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

---@param linefeed string
---@param text string
---@return string[]
M.records = function(linefeed, text)
  local records = {}
  for record in each_record(linefeed, text) do
    table.insert(records, record)
  end
  return records
end

---@param lines string[]
---@param start integer
---@param finish integer
---@return string[]
M.slice = function(lines, start, finish)
  return vim.list_slice(lines, math.floor(start + 1), math.floor(finish))
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

local worker = function(before, after)
  return vim.text.diff(before, after, { result_type = "indices" })
end

---@param before string
---@param after string
---@return integer[][]
M.indices = function(before, after)
  return async.work(worker, before, after)
end

return M
