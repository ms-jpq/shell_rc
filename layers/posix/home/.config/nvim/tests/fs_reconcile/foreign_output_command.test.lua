local T = require "tests.lib"

T.test({ "foreign output command", timeout = 10000 }, function()
  local path = T.file { "a", "b" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local writes = 0
  vim.api.nvim_create_autocmd({ "FileWriteCmd" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
      vim.fn.writefile({ "a", "agent" }, path)
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "local" })
  vim.cmd [[1,1write! %]]
  assert(writes == 1)
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "local", "agent" })
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local", "agent" })
  end, { timeout = 1500 })
  assert(not vim.bo.modified)
end)
