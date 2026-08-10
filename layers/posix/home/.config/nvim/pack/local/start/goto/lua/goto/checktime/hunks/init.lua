local apply = require "goto.checktime.hunks.apply"
local async = require "goto.async"
local core = require "goto.checktime.hunks.merge"

local M = {}

local merge_work = function(linefeed, base, local_text, remote_text)
  local ok, response = xpcall(function()
    return require("goto.checktime.hunks.merge").merge(linefeed, base, local_text, remote_text)
  end, debug.traceback)
  return vim.json.encode(ok and { result = response } or { error = response })
end

---@param linefeed string
---@param base string
---@param local_text string
---@param remote_text string
---@return string
M.merge = function(linefeed, base, local_text, remote_text)
  if local_text == base then
    return remote_text
  elseif remote_text == base then
    return local_text
  end

  local response = vim.json.decode(async.work(merge_work, linefeed, base, local_text, remote_text))
  if response.error then
    error(response.error, 0)
  end
  return response.result
end

local diff_work = function(before, after)
  local ok, response = xpcall(function()
    return vim.text.diff(before, after, { result_type = "indices" })
  end, debug.traceback)
  return vim.json.encode(ok and { result = response } or { error = response })
end

local diff = function(before, after, after_records)
  local response = vim.json.decode(async.work(diff_work, before, after))
  if response.error then
    error(response.error, 0)
  end
  return core.changes(after_records, response.result)
end

---@param buf integer
---@param current ChecktimeBuffer
---@param text string
---@param mark fun(start: integer, finish: integer)
---@return boolean
M.replace = function(buf, current, text, mark)
  local changedtick = vim.api.nvim_buf_get_changedtick(buf)
  local whole = diff(current.text, text, core.records(current.linefeed, text))
  if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_changedtick(buf) ~= changedtick then
    return false
  end
  return apply.run(buf, current, text, whole, mark)
end

return M
