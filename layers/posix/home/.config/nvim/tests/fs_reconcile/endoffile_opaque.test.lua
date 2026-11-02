local T = require "tests.lib"

T.test({ "endoffile opaque", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "base\r\n\026", 0))
  assert(vim.uv.fs_close(fd))
  vim.cmd.edit(path)
  assert(vim.bo.fileformat == "dos")
  assert(vim.bo.endoffile)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "base" }))

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  require("goto.async").sleep(750)

  assert(vim.bo.endoffile)
  assert(not vim.bo.modified)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "base" }))
  assert(vim.fn.readblob(path) == "base\r\n\026")

  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
  end)
  assert(vim.bo.endoffile)
end)
