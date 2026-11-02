local T = require "tests.lib"

T.test({ "same version remote", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)

  local util = require "goto.fs_reconcile.util"
  T.patch(util, "same_version", function()
    return true
  end)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.fn.writefile({ "agent" }, path)
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        modified = vim.bo.modified,
      }
    end,
  })
end)
