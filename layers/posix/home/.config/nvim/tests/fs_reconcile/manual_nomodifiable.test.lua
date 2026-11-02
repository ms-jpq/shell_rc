local T = require "tests.lib"

T.test({ "manual nomodifiable", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd [[setlocal nomodifiable]]
  vim.cmd.write()
  assert(vim.deep_equal(vim.fn.readfile(path), { "local" }))
  assert(not vim.bo.modified)
end)
