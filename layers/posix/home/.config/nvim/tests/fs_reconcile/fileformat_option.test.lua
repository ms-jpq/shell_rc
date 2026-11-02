local T = require "tests.lib"

T.test({ "fileformat option", timeout = 10000 }, function()
  local path = T.file { "base", "second" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  vim.bo.fileformat = "dos"
  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "local" })

  T.eventually(function()
    return vim.fn.readblob(path) == "local\r\nsecond\r\n" and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        fileformat = vim.bo.fileformat,
        disk = vim.fn.readblob(path),
        modified = vim.bo.modified,
      }
    end,
  })
end)
