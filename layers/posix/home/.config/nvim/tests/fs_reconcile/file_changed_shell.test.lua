local T = require "tests.lib"

T.test({ "file changed shell", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.fn.writefile({ "agent" }, path)
  vim.v.fcs_choice = "ask"
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })

  assert(vim.v.fcs_choice == "")
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
  end, {
    message = function()
      return vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end,
  })

  vim.b.__fs_reconcile__.close()
  vim.v.fcs_choice = ""
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })
  assert(vim.v.fcs_choice == "ask")
  assert(vim.b.__fs_reconcile__ == nil)
end)
