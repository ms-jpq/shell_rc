local T = require "tests.lib"

T.test({ "write fileformat", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd [[write ++ff=dos]]

  assert(vim.fn.readblob(path) == "local\r\n")
  assert(vim.bo.fileformat == "unix")
  assert(not vim.bo.modified)
  T.eventually(function()
    return vim.bo.fileformat == "unix" and not vim.bo.modified
  end, { timeout = 1500 })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "saved" })
  T.eventually(function()
    return vim.fn.readblob(path) == "saved\n" and not vim.bo.modified
  end)
end)
