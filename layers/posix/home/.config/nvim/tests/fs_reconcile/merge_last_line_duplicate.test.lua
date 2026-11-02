local T = require "tests.lib"

T.test({ "last-line end-of-line changes do not duplicate content", timeout = 10000, isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks").merge

  local base = { text = "a", endofline = false }
  local local_value = { text = "a", endofline = true }
  local remote = { text = "x\na", endofline = true }

  local merged = merge(base, local_value, remote)
  assert(
    vim.deep_equal(merged, remote),
    vim.inspect { base = base, local_value = local_value, remote = remote, merged = merged }
  )
end)
