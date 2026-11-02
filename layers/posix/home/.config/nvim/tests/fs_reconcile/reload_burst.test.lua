local T = require "tests.lib"

T.test({ "reload burst", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  for _ = 1, 8 do
    vim.cmd [[edit!]]
  end

  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end, { timeout = 1000 })

  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
  end, {
    message = function()
      return vim.inspect {
        attached = vim.b.__fs_reconcile__ ~= nil,
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
      }
    end,
  })
end)
