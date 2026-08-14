local M = {}

---@class FsReconcileHunk
---@field start integer
---@field finish integer
---@field lines string[]
---@field slot? integer

---@class FsReconcileReplacement
---@field changes FsReconcileHunk[]
---@field trailing_empty boolean

---@param linefeed string
---@param text string
---@return string[]
M.records = function(linefeed, text)
  if text == "" then
    return {}
  end

  local parts = vim.split(text, linefeed, { plain = true })
  local records = {}
  for index = 1, #parts - 1 do
    table.insert(records, parts[index] .. linefeed)
  end
  if string.sub(text, -#linefeed) ~= linefeed then
    table.insert(records, parts[#parts])
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

return M
