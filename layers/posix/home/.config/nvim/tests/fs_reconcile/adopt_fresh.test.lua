local T = require "tests.lib"

T.test({ "adopt fresh", timeout = 10000 }, function()
  local util = require "goto.fs_reconcile.util"
  local unchanged = util.unchanged
  local checks = 0
  T.patch(util, "unchanged", function(...)
    checks = checks + 1
    return unchanged(...)
  end)

  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})

  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil and checks > 0
  end, { timeout = 1000 })
end)
