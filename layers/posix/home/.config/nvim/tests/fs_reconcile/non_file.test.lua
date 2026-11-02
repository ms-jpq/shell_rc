local T = require "tests.lib"

T.test({ "non file", timeout = 10000 }, function()
  local util = require "goto.fs_reconcile.util"
  local path = vim.fn.tempname()
  assert(vim.fn.system { "mkfifo", path } == "")
  assert(vim.v.shell_error == 0)

  local buf = vim.api.nvim_get_current_buf()
  local base, state = util.read_file(buf, path)
  assert(base == nil)
  assert(state == util.READ.OPAQUE)
end)
