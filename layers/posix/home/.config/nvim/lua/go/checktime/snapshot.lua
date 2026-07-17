local M = {}

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
  return vim.api.nvim_buf_get_lines(buf, 0, -1, true)
end

M.get = function(buf)
  return vim.b[buf].__checktime_base__
end

M.set = function(buf)
  vim.b[buf].__checktime_base__ = M.buffer(buf)
end

M.read = function(name)
  local before = vim.uv.fs_stat(name)
  if not before then
    return nil, "missing"
  elseif before.size > MAX_BYTES then
    return nil, "large"
  end

  local ok, lines = pcall(vim.fn.readfile, name, "b")
  if not ok then
    return nil, "unreadable"
  elseif not same_version(before, vim.uv.fs_stat(name)) then
    return nil, "changing"
  end

  local endofline = lines[#lines] == ""
  if endofline then
    table.remove(lines)
  end

  local fileformat = lines[1] and lines[1]:sub(-1) == "\r" and "dos" or "unix"
  if fileformat == "dos" then
    for index, line in pairs(lines) do
      lines[index] = line:sub(1, -2)
    end
  end

  return lines
end

return M
