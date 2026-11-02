local T = require "tests.lib"

T.test({ "buftype detach", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end, { timeout = 1000 })

  vim.cmd [[setlocal buftype=nofile]]
  vim.api.nvim_exec_autocmds({ "OptionSet" }, { pattern = "buftype" })
  assert(vim.b.__fs_reconcile__ == nil)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "base" }))
end)
