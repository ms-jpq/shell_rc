local T = require "tests.lib"

T.test({ "initial remote", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)

  local util = require "goto.fs_reconcile.util"
  local read_file = util.read_file
  local once = true
  T.patch(util, "read_file", function(buf, name)
    if once then
      once = false
      vim.fn.writefile({ "agent" }, name)
    end
    return read_file(buf, name)
  end)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and vim.deep_equal(vim.fn.readfile(path), { "agent" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })
end)
