local T = require "tests.lib"

T.test({ "rebind attach", timeout = 10000 }, function()
  local initial = T.file { "base" }
  vim.cmd.edit(initial)

  local attach = vim.api.nvim_buf_attach
  local calls = 0
  T.patch(vim.api, "nvim_buf_attach", function(...)
    calls = calls + 1
    return attach(...)
  end)

  local util = require "goto.fs_reconcile.util"
  local poller = util.poller
  local observed
  T.patch(util, "poller", function(path, interval, wake)
    observed = path
    return poller(path, interval, wake)
  end)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  for _ = 1, 8 do
    local path = vim.fn.tempname()
    vim.cmd.file(path)
    T.eventually(function()
      return observed == vim.api.nvim_buf_get_name(0)
    end)
  end
  vim.api.nvim_buf_attach = attach

  assert(calls == 1, vim.inspect { calls = calls })
end)
