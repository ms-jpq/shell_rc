local T = require "tests.lib"

T.test({ "retarget poller failure", timeout = 10000 }, function()
  local util = require "goto.fs_reconcile.util"
  local poller = util.poller
  local attempts = 0
  T.patch(util, "poller", function(...)
    attempts = attempts + 1
    if attempts == 2 then
      return
    end
    return poller(...)
  end)

  local before, after = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "base" }, before)
  vim.cmd.edit(before)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end, { timeout = 1000 })

  vim.api.nvim_buf_set_name(0, after)
  T.eventually(function()
    return attempts == 2
  end, { timeout = 1000 })
  assert(vim.b.__fs_reconcile__ == nil)
  assert(vim.bo.autoread)
end)
