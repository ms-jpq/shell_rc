local T = require "tests.lib"

T.test({ "suspend", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.api.nvim_exec_autocmds({ "VimSuspend" }, {})

  assert(vim.b.__fs_reconcile__)
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "local" }) and not vim.bo.modified
  end)
end)
