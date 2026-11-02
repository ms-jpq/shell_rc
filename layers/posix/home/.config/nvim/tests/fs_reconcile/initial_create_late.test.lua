local T = require "tests.lib"

T.test({ "initial create late", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)
  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.modified
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect {
        attached = vim.b.__fs_reconcile__ ~= nil,
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })
end)
