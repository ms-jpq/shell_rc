local T = require "tests.lib"

T.test({ "stale adopt", timeout = 10000 }, function()
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"

  T.patch(util, "poller", function()
    return { close = function() end }
  end)

  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end, { timeout = 1000 })

  local plan = hunks.plan
  local injected = false
  T.patch(hunks, "plan", function(...)
    if not injected then
      injected = true
      vim.fn.writefile({ "remote two" }, path)
    end
    return plan(...)
  end)

  vim.fn.writefile({ "remote one" }, path)
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })
  T.eventually(function()
    return injected and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "remote two" })
  end, { timeout = 3000 })
end)
