local T = require "tests.lib"

T.test({ "force retarget", timeout = 10000 }, function()
  local run = require "tests.fs_reconcile.retarget"
  local native = run "write!"
  require "goto.fs_reconcile"
  local reconciled = run "write!"
  assert(vim.deep_equal(reconciled, native), vim.inspect { native = native, reconciled = reconciled })
end)
