local T = require "tests.lib"

T.test({ "modifiable", timeout = 10000 }, function()
  local path = T.file { "before" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.bo.modifiable = false
  vim.fn.writefile({ "remote" }, path)
  require("goto.async").sleep(300)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "before" }))

  vim.bo.modifiable = true
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "remote" })
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
      }
    end,
  })
end)
