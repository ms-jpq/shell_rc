local T = require "tests.lib"

T.test({ "encoding concurrent", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  vim.cmd.edit(path)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "café", "before", "before" })
  vim.bo.fileencoding = "latin1"
  vim.cmd.write()
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})

  vim.bo.fileencoding = "utf-8"
  vim.api.nvim_buf_set_lines(0, 1, 2, true, { "local" })
  vim.fn.writefile({ "caf\233", "before", "agent" }, path)
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "café", "local", "agent" })
      and vim.fn.readblob(path) == "café\nlocal\nagent\n"
      and not vim.bo.modified
  end)

  vim.fn.writefile({ "café", "local", "après" }, path)
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "café", "local", "après" })
      and not vim.bo.modified
  end)
  assert(vim.bo.fileencoding == "utf-8")
end)
