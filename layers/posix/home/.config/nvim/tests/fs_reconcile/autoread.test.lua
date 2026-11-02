local T = require "tests.lib"

T.test({ "autoread", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  vim.bo.autoread = true

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  assert(not vim.bo.autoread)

  local second_path = T.file { "second" }
  vim.cmd.edit(second_path)
  assert(not vim.bo.autoread)
end)
