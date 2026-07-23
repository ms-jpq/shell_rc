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

M.read = function(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local before = vim.uv.fs_stat(name)
  if not before then
    return nil
  elseif before.size > MAX_BYTES then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, name)
  if not ok then
    return M.RETRY
  elseif not same_version(before, vim.uv.fs_stat(name)) then
    return M.RETRY
  end

  local encoding = vim.bo[buf].fileencoding
  if encoding ~= "" and encoding ~= vim.o.encoding then
    lines = vim
      .iter(lines)
      :map(function(line)
        return vim.fn.iconv(line, encoding, vim.o.encoding)
      end)
      :totable()
  end

  return lines
end

return M
