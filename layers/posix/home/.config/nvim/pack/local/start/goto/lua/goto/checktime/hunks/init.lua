local async = require "goto.async"
local core = require "goto.checktime.hunks.merge"

local M = {}

local buffer_lines = function(linefeed, text)
  return vim
    .iter(core.records(linefeed, text))
    :map(function(record)
      return string.sub(record, -#linefeed) == linefeed and string.sub(record, 1, -#linefeed - 1) or record
    end)
    :totable()
end

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
  local patches = core.row_patches(whole)
  local restore = require("goto.checktime.view").capture(buf, whole)

  vim.api.nvim_buf_call(buf, function()
    for index, hunk in vim.iter(patches):rev():enumerate() do
      if index == #patches then
        vim.cmd [[let &undolevels=&undolevels]]
      else
        vim.cmd.undojoin()
      end

      local lines = buffer_lines(current.linefeed, table.concat(hunk.lines))
      vim.api.nvim_buf_set_lines(buf, hunk.start, hunk.finish, true, lines)
      if #lines > 0 then
        mark(hunk.start, hunk.start + #lines)
      end
    end

    if not current.endofline then
      local count = vim.api.nvim_buf_line_count(buf)
      local last = unpack(vim.api.nvim_buf_get_lines(buf, count - 1, count, true))
      local ending = string.sub(text, -#current.linefeed) == current.linefeed
      if ending ~= (count > 1 and last == "") then
        vim.cmd.undojoin()
        vim.api.nvim_buf_set_lines(buf, ending and -1 or -2, -1, true, ending and { "" } or {})
      end
    end
  end)
  restore()
  return true
end

return M
