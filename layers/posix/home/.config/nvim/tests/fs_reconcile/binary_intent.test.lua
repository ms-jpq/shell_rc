local T = require "tests.lib"

T.test({ "binary intent", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "base\r\n", 0))
  assert(vim.uv.fs_close(fd))
  vim.cmd.edit(path)
  assert(vim.bo.fileformat == "dos")
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd [[setlocal binary]]
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  T.eventually(function()
    return vim.fn.readblob(path) == "local\n" and vim.bo.fileformat == "dos" and not vim.bo.modified
  end)

  vim.cmd [[setlocal nobinary]]
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "saved" })
  T.eventually(function()
    return vim.fn.readblob(path) == "saved\r\n" and vim.bo.fileformat == "dos" and not vim.bo.modified
  end)
end)
