local async = require "goto.async"
local lib = require "goto.lib"

local M = {}

---@class ChecktimeBuffer
---@field linefeed string
---@field text string
---@field endofline boolean
---@field final_empty boolean

---@alias ChecktimeFileObservation "text"|"opaque"|"unstable"|"missing"

---@class ChecktimeFileObservations
M.OBSERVATIONS = {
  TEXT = "text",
  OPAQUE = "opaque",
  UNSTABLE = "unstable",
  MISSING = "missing",
}

local MAX_BYTES = 2 * 1024 * 1024
local BOM = "\239\187\191"

---@param buf integer
---@param text string
---@return string?
local decode = function(buf, text)
  local encoding = vim.bo[buf].fileencoding
  if encoding ~= "" and encoding ~= vim.o.encoding then
    local ok, converted = pcall(vim.fn.iconv, text, encoding, vim.o.encoding)
    if not ok or (text ~= "" and converted == "") then
      return nil
    end
    text = converted
  end
  local has_bom = string.sub(text, 1, #BOM) == BOM
  if has_bom ~= vim.bo[buf].bomb then
    return nil
  elseif has_bom then
    text = string.sub(text, #BOM + 1)
  end

  local remainder = string.gsub(text, lib.buf_linefeed(buf), "")
  if string.find(remainder, "[\r\n]") then
    return nil
  end
  return text
end

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

---@param before uv.fs_stat.result?
---@param after uv.fs_stat.result?
---@return boolean
M.same_version = function(before, after)
  return same_version(before, after)
end

---@param buf integer
---@return ChecktimeBuffer
M.buffer = function(buf)
  local endofline = vim.bo[buf].endofline
  local linefeed = lib.buf_linefeed(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local text = table.concat(lines, linefeed)
  return {
    linefeed = linefeed,
    text = endofline and text .. linefeed or text,
    endofline = endofline,
    final_empty = lines[#lines] == "",
  }
end

---@param current ChecktimeBuffer
---@param text string
---@return string
M.merge_text = function(current, text)
  local linefeed = current.linefeed
  if current.final_empty and not current.endofline then
    return text .. linefeed
  elseif current.endofline then
    return string.sub(text, -#linefeed) == linefeed and text or text .. linefeed
  else
    return text
  end
end

---@param current ChecktimeBuffer
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

---@param current ChecktimeBuffer
---@param text string
---@return string
M.normalize = function(current, text)
  return M.buffer_text(current, M.merge_text(current, text))
end

---@param buf integer
---@param content boolean
---@return ChecktimeFileObservation, uv.fs_stat.result?, string?
local read_file = function(buf, content)
  local name = vim.api.nvim_buf_get_name(buf)
  local _, before = async.uv.fs_stat(name)
  async.scheduled()
  if not vim.api.nvim_buf_is_valid(buf) then
    return M.OBSERVATIONS.UNSTABLE, nil, nil
  end
  if not before then
    return M.OBSERVATIONS.MISSING, nil, nil
  elseif before.size > MAX_BYTES or not content then
    return M.OBSERVATIONS.OPAQUE, before, nil
  end

  local ok, text = pcall(vim.fn.readblob, name)
  if not ok then
    return M.OBSERVATIONS.UNSTABLE, nil, nil
  elseif type(text) ~= "string" then
    return M.OBSERVATIONS.OPAQUE, nil, nil
  end
  text = decode(buf, assert(text))
  if not text then
    return M.OBSERVATIONS.OPAQUE, nil, nil
  end

  local _, after = async.uv.fs_stat(name)
  async.scheduled()
  if not vim.api.nvim_buf_is_valid(buf) or not same_version(before, after) then
    return M.OBSERVATIONS.UNSTABLE, nil, nil
  end
  return M.OBSERVATIONS.TEXT, before, text
end

---@param buf integer
---@param expected string
---@return ChecktimeBase?, boolean diverged
M.attest = function(buf, expected)
  local observation, version, text = read_file(buf, true)
  if observation ~= M.OBSERVATIONS.TEXT then
    return nil, false
  end
  if text ~= expected then
    return nil, true
  end
  return { text = text, version = version }, false
end

---@param buf integer
---@return ChecktimeFileObservation, uv.fs_stat.result?, string?
M.read = function(buf)
  local content = vim.bo[buf].modified or #vim.fn.win_findbuf(buf) > 0
  return read_file(buf, content)
end

---@param buf integer
---@param version uv.fs_stat.result?
---@return boolean
M.unchanged = function(buf, version)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local name = vim.api.nvim_buf_get_name(buf)
  async.scheduled()
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local current = vim.uv.fs_stat(name)
  return version and same_version(version, current) or not current
end

return M
