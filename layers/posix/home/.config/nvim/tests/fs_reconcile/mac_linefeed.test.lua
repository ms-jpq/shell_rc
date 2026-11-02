local T = require "tests.lib"

T.test({ "mac linefeed", timeout = 10000 }, function()
  vim.opt.fileformats:append "mac"
  local path = vim.fn.tempname()
  vim.fn.writefile({ "base-1\rbase-2\r" }, path, "b")
  vim.cmd.edit(path)
  assert(vim.bo.fileformat == "mac", vim.inspect { fileformat = vim.bo.fileformat })

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  vim.fn.writefile({ "remote-1\r" }, path, "b")

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "remote-1" }) and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        modified = vim.bo.modified,
      }
    end,
  })
end)
