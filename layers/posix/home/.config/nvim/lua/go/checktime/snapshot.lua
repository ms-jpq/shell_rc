local M = {}

local MAX_BYTES = 2 * 1024 * 1024

M.buffer = function(buf)
  return {
    lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true),
    endofline = vim.bo[buf].endofline,
    fileformat = vim.bo[buf].fileformat,
  }
end

M.base = function(buf)
  return vim.b[buf].__checktime_base__
end

M.save = function(buf)
  vim.b[buf].__checktime_base__ = M.buffer(buf)
end

M.read = function(name)
  local stat = vim.uv.fs_stat(name)
  if stat and stat.size > MAX_BYTES then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, name, "b")
  if not ok then
    return nil
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

  return { lines = lines, endofline = endofline, fileformat = fileformat }
end

return M
