local T = require "tests.lib"

T.test({ "opaque recover", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.fn.writefile({ string.rep("x", 2 * 1024 * 1024 + 1) }, path)
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        attached = vim.b.__fs_reconcile__ ~= nil,
        modified = vim.bo.modified,
      }
    end,
  })
end)
