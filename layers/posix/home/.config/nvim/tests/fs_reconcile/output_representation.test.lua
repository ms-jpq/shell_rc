local T = require "tests.lib"

T.test({ "output representation", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd [[write ++ff=dos]]
  assert(vim.fn.readblob(path) == "local\r\n")
  assert(vim.bo.fileformat == "unix")

  vim.cmd [[setlocal fileformat=mac]]
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "edited" })
  T.eventually(function()
    return vim.fn.readblob(path) == "edited\r" and not vim.bo.modified
  end)
end)
