local T = require "tests.lib"

T.test({ "file from unnamed", timeout = 10000 }, function()
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  vim.cmd.enew()

  local path = vim.fn.tempname()
  vim.cmd.file(path)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.write()

  assert(vim.b.__fs_reconcile__ ~= nil)
  assert(vim.deep_equal(vim.fn.readfile(path), { "local" }))
  assert(not vim.bo.modified)
end)
