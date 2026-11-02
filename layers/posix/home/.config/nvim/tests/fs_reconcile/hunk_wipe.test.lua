local T = require "tests.lib"

T.test({ "hunk wipe", timeout = 10000 }, function()
  local path = T.file { "one", "two" }
  vim.cmd.edit(path)

  local hunks = require "goto.fs_reconcile.hunks"
  local plan = hunks.plan
  local wiped = false
  T.patch(hunks, "plan", function(...)
    if not wiped then
      wiped = true
      vim.cmd [[bwipeout!]]
    end
    return plan(...)
  end)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  vim.fn.writefile({ "agent", "TWO" }, path)

  T.eventually(function()
    return wiped
  end, { timeout = 1000 })
end)
