local T = require "tests.lib"

T.test({ "foreign write command", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buffer = 0,
    callback = function()
      vim.cmd [[noautocmd write! ++p]]
    end,
  })

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  assert(vim.b.__fs_reconcile__ ~= nil)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.write()
  assert(vim.deep_equal(vim.fn.readfile(path), { "local" }))
  assert(not vim.bo.modified)
end)
