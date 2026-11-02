local T = require "tests.lib"

T.test({ "read error", timeout = 10000 }, function()
  local util = require "goto.fs_reconcile.util"
  local path = T.file { "base" }
  vim.cmd.edit(path)

  local fs_stat = vim.uv.fs_stat
  T.patch(vim.uv, "fs_stat", function()
    return nil, "EACCES: permission denied", "EACCES"
  end)
  local base, state = util.read_file(0, path)
  vim.uv.fs_stat = fs_stat

  assert(base == nil)
  assert(state == util.READ.UNSTABLE)
end)
