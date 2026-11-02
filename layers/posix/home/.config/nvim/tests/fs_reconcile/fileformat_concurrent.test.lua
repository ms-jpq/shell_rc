local T = require "tests.lib"

T.test({ "fileformat concurrent", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  vim.bo.fileformat = "dos"
  vim.fn.writefile({ "agent" }, path)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and vim.bo.fileformat == "dos"
      and not vim.bo.modified
      and vim.fn.readblob(path) == "agent\n"
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        fileformat = vim.bo.fileformat,
        modified = vim.bo.modified,
        disk = vim.fn.readblob(path),
      }
    end,
  })

  vim.cmd [[write!]]
  assert(vim.fn.readblob(path) == "agent\r\n")
  assert(not vim.bo.modified)
end)
