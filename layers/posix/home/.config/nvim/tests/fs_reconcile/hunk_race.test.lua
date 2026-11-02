local T = require "tests.lib"

T.test({ "hunk race", timeout = 10000 }, function()
  local path = T.file { "a", "b" }
  vim.cmd.edit(path)

  local hunks = require "goto.fs_reconcile.hunks"
  local plan = hunks.plan
  local changed = true
  T.patch(hunks, "plan", function(...)
    if changed then
      changed = false
      vim.api.nvim_buf_set_lines(0, 0, 1, true, { "user" })
    end
    return plan(...)
  end)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  vim.fn.writefile({ "a", "agent" }, path)

  T.eventually(function()
    return not changed
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "user", "agent" })
      and vim.deep_equal(vim.fn.readfile(path), { "user", "agent" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        changed = changed,
        modified = vim.bo.modified,
      }
    end,
  })

  vim.cmd [[write!]]
  assert(vim.deep_equal(vim.fn.readfile(path), { "user", "agent" }))
  assert(not vim.bo.modified)

  hunks.plan = plan
end)
