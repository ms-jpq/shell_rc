local apply = require "goto.fs_reconcile.hunks.apply"
local async = require "goto.async"
local diff = require "goto.fs_reconcile.hunks.diff"

local M = {}

---@class FsReconcileBuffer
---@field linefeed string
---@field text string
---@field endofline boolean
---@field final_empty boolean
---@field changedtick? integer

local merge_work = function(linefeed, base, local_text, remote_text)
  local ok, response = xpcall(function()
    return require("goto.fs_reconcile.hunks.merge").merge(linefeed, base, local_text, remote_text)
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

local index_diff = function(before, after)
  local response = vim.json.decode(async.work(diff_work, before, after))
  if response.error then
    error(response.error, 0)
  end
  return response.result
end

---@param current FsReconcileBuffer
---@param text string
---@return FsReconcileReplacement
M.replacement = function(current, text)
  local indices = index_diff(current.text, text)
  return {
    changes = diff.changes(diff.records(current.linefeed, text), indices),
    trailing_empty = string.sub(text, -#current.linefeed) == current.linefeed,
  }
end

---@param buf integer
---@param current FsReconcileBuffer
---@param replacement FsReconcileReplacement
---@param mark fun(start: integer, finish: integer)
---@param rewrite? fun(apply: fun(): boolean): boolean
---@return boolean
M.apply = function(buf, current, replacement, mark, rewrite)
  if
    not vim.api.nvim_buf_is_valid(buf)
    or current.changedtick and current.changedtick ~= vim.api.nvim_buf_get_changedtick(buf)
  then
    return false
  end
  return apply.run(buf, current, replacement, mark, rewrite)
end

---@param buf integer
---@param current FsReconcileBuffer
---@param text string
---@param mark fun(start: integer, finish: integer)
---@param rewrite? fun(apply: fun(): boolean): boolean
---@return boolean
M.replace = function(buf, current, text, mark, rewrite)
  return M.apply(buf, current, M.replacement(current, text), mark, rewrite)
end

return M
