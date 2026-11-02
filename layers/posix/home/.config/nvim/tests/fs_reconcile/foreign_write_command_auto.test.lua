local T = require "tests.lib"

T.test({ "foreign write command auto", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local writes = 0
  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "local" }) and not vim.bo.modified
  end, { timeout = 1500 })
  assert(vim.b.__fs_reconcile__ ~= nil)
  assert(writes == 0)
end)
