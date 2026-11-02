local T = require "tests.lib"

T.test({ "trace startup", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)

  local util = require "goto.fs_reconcile.util"
  local read_file = util.read_file
  local reads = 0
  T.patch(util, "read_file", function(...)
    reads = reads + 1
    return read_file(...)
  end)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.fn.writefile({ "remote" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "remote" })
      and vim.deep_equal(vim.fn.readfile(path), { "remote" })
      and not vim.bo.modified
      and vim.b.__fs_reconcile__ ~= nil
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
        attached = vim.b.__fs_reconcile__ ~= nil,
        reads = reads,
      }
    end,
  })
end)
