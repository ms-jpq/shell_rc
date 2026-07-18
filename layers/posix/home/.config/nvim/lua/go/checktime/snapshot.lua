local M = {}

M.BASE = "__checktime_base__"

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

M.read = function(name)
  local before = vim.uv.fs_stat(name)
  if not before then
    return nil
  elseif before.size > MAX_BYTES then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, name, "b")
  if not ok then
    return nil
  elseif not same_version(before, vim.uv.fs_stat(name)) then
    return nil
  end

  if lines[#lines] == "" then
    table.remove(lines)
  end

  return lines
end

return M
