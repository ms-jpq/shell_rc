local T = require "tests.lib"

T.test({ "independent edits merge in a large line", timeout = 10000, isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge

  local base = string.rep("a", 32768) .. "\n"
  local local_text = "L" .. string.sub(base, 2)
  local remote_text = string.sub(base, 1, -3) .. "R\n"

  assert(
    merge(string.sub(base, 1, -2), string.sub(local_text, 1, -2), string.sub(remote_text, 1, -2))
      == "L" .. string.sub(base, 2, -3) .. "R"
  )
end)
