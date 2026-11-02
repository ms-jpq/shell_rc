local T = require "tests.lib"

T.test({ "decoder nul", timeout = 10000 }, function()
  local path = T.file { "café" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd [[write ++enc=latin1]]
  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "a\0b\n", 0))
  assert(vim.uv.fs_close(fd))
  require("goto.async").sleep(750)

  assert(vim.b.__fs_reconcile__ ~= nil)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "café" }))
  assert(vim.fn.readblob(path) == "a\0b\n")

  fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "agent\n", 0))
  assert(vim.uv.fs_close(fd))
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.modified
  end)
end)
