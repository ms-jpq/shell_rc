local T = require "tests.lib"

T.test({ "local conflicts win across many lines", timeout = 10000, isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge

  local count = 10 * 1024
  local base = string.rep("a\n", count)
  local local_text = string.rep("b\n", count)
  local remote_text = string.rep("c\n", count)

  assert(
    merge(string.sub(base, 1, -2), string.sub(local_text, 1, -2), string.sub(remote_text, 1, -2))
      == string.sub(local_text, 1, -2)
  )
end)
