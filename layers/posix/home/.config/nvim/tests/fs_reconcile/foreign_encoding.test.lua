local T = require "tests.lib"

T.test({ "foreign encoding", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local utf16 = "\255\254a\0g\0e\0n\0t\0\n\0"
  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, utf16, 0))
  assert(vim.uv.fs_close(fd))

  T.eventually(function()
    return vim.fn.readblob(path) == utf16 and vim.b.__fs_reconcile__ ~= nil
  end, { timeout = 1000 })
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "base" }))
  assert(not vim.bo.modified)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  require("goto.async").sleep(1000)
  assert(vim.fn.readblob(path) == utf16)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local" }))
  assert(vim.bo.modified)
end)
