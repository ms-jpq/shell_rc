local lib = require "goto.lib"

local M = {}

---@class ChecktimeCurrent
---@field linefeed string
---@field text string
---@field endofline boolean
---@field final_empty boolean
---@field changedtick integer

---@alias ChecktimeState "reconcile"|"opaque"|"retry"|"none"

---@class ChecktimeStates
---@field RECONCILE ChecktimeState
---@field OPAQUE ChecktimeState
---@field RETRY ChecktimeState
---@field NONE ChecktimeState
M.STATES = {
  RECONCILE = "reconcile",
  OPAQUE = "opaque",
  RETRY = "retry",
  NONE = "none",
}

local MAX_BYTES = 2 * 1024 * 1024
local BOM = "\239\187\191"

local same_version = function(before, after)
  return before
    and after
    and before.dev == after.dev
    and before.ino == after.ino
    and before.size == after.size
    and before.mtime.sec == after.mtime.sec
    and before.mtime.nsec == after.mtime.nsec
    and before.ctime.sec == after.ctime.sec
    and before.ctime.nsec == after.ctime.nsec
end

---@param buf integer
---@return ChecktimeCurrent
M.current = function(buf)
  local endofline = vim.bo[buf].endofline
  local linefeed = lib.buf_linefeed(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local text = table.concat(lines, linefeed)
  return {
    linefeed = linefeed,
    text = endofline and text .. linefeed or text,
    endofline = endofline,
    final_empty = lines[#lines] == "",
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
  }
end

---@param current ChecktimeCurrent
---@param text string
---@return string
M.row_text = function(current, text)
  local linefeed = current.linefeed
  if current.final_empty and not current.endofline then
    return text .. linefeed
  elseif current.endofline then
    return string.sub(text, -#linefeed) == linefeed and text or text .. linefeed
  else
    return text
  end
end

---@param current ChecktimeCurrent
---@param text string
---@return string
M.buffer_text = function(current, text)
  local linefeed = current.linefeed
  local ending = string.sub(text, -#linefeed) == linefeed

  if text == linefeed then
    return ""
  elseif current.endofline then
    return ending and text or text .. linefeed
  elseif ending then
    return string.sub(text, 1, -#linefeed - 1)
  else
    return text
  end
end

---@param current ChecktimeCurrent
---@param text string
---@return string
M.fit = function(current, text)
  return M.buffer_text(current, M.row_text(current, text))
end

---@param buf integer
---@return ChecktimeState, uv.fs_stat.result?, string?
M.read = function(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local before = vim.uv.fs_stat(name)
  if not before then
    return M.STATES.NONE, nil, nil
  elseif before.size > MAX_BYTES or (not vim.bo[buf].modified and #vim.fn.win_findbuf(buf) == 0) then
    return M.STATES.OPAQUE, before, nil
  end

  local ok, text = pcall(vim.fn.readblob, name)
  if not ok then
    return M.STATES.RETRY, nil, nil
  end

  if type(text) ~= "string" then
    return M.STATES.OPAQUE, nil, nil
  end

  local encoding = vim.bo[buf].fileencoding
  if encoding ~= "" and encoding ~= vim.o.encoding then
    local ok, converted = pcall(vim.fn.iconv, text, encoding, vim.o.encoding)
    if not ok or (text ~= "" and converted == "") then
      return M.STATES.OPAQUE, nil, nil
    end
    text = converted
  end
  local has_bom = string.sub(text, 1, #BOM) == BOM
  if has_bom ~= vim.bo[buf].bomb then
    return M.STATES.OPAQUE, nil, nil
  elseif has_bom then
    text = string.sub(text, #BOM + 1)
  end

  local remainder = string.gsub(text, lib.buf_linefeed(buf), "")
  if string.find(remainder, "[\r\n]") then
    return M.STATES.OPAQUE, nil, nil
  end

  if not same_version(before, vim.uv.fs_stat(name)) then
    return M.STATES.RETRY, nil, nil
  end

  return M.STATES.RECONCILE, before, text
end

---@param buf integer
---@param version uv.fs_stat.result?
---@return boolean
M.unchanged = function(buf, version)
  local current = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
  return version and same_version(version, current) or not current
end

return M
