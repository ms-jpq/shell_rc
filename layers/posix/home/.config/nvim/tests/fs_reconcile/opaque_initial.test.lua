local T = require "tests.lib"

T.test({ "opaque initial", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local utf16 = "\255\254b\0a\0s\0e\0\n\0"
  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, utf16, 0))
  assert(vim.uv.fs_close(fd))
  vim.cmd.edit(path)
  assert(vim.bo.fileencoding == "utf-16le", vim.inspect { fileencoding = vim.bo.fileencoding })

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end, { timeout = 1000 })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.write()
  assert(not vim.bo.modified)
end)
