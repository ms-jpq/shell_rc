local lib = require "go.lib"

local M = {}

M.BASE = "__checktime_base__"
M.RETRY = {}

local MAX_BYTES = 2 * 1024 * 1024

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

M.buffer = function(buf)
  local linefeed = lib.buf_linefeed(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local text = table.concat(lines, linefeed)
  return vim.bo[buf].endofline and text .. linefeed or text
end

M.read = function(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local before = vim.uv.fs_stat(name)
  if not before then
    return nil
  elseif before.size > MAX_BYTES then
    return nil
  end

  local ok, text = pcall(vim.fn.readblob, name)
  if not ok then
    return M.RETRY
  end

  local encoding = vim.bo[buf].fileencoding
  if encoding ~= "" and encoding ~= vim.o.encoding then
    text = vim.fn.iconv(text, encoding, vim.o.encoding)
  end
  if vim.bo[buf].bomb then
    text = string.gsub(text, "^\239\187\191", "")
  end

  if not same_version(before, vim.uv.fs_stat(name)) then
    return M.RETRY
  end

  return text
end

return M
