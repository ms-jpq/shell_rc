local T = require "tests.lib"

T.test({ "same version concurrent", timeout = 10000 }, function()
  local util = require "goto.fs_reconcile.util"
  local path = T.file { "a", "b" }
  vim.cmd.edit(path)

  T.patch(util, "same_version", function()
    return true
  end)

  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "A" })
  vim.fn.writefile({ "a", "B" }, path)
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "A", "B" })
      and vim.deep_equal(vim.fn.readfile(path), { "A", "B" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect { buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true), disk = vim.fn.readfile(path) }
    end,
  })
end)
