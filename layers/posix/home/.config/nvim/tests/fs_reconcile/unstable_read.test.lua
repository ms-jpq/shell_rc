local T = require "tests.lib"

T.test({ "unstable read", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)

  local util = require "goto.fs_reconcile.util"
  local read_file = util.read_file
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  local unstable = true
  T.patch(util, "read_file", function(name, buf)
    if unstable then
      unstable = false
      return nil, util.READ.UNSTABLE
    end
    return read_file(name, buf)
  end)

  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return not unstable
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        unstable = unstable,
      }
    end,
  })
end)
