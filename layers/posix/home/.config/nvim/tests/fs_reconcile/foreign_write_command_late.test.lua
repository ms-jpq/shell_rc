local T = require "tests.lib"

T.test({ "foreign write command late", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buffer = 0,
    callback = function()
      vim.cmd [[noautocmd write! ++p]]
      vim.bo.modified = false
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "foreign" })
  vim.cmd.write()
  assert(vim.deep_equal(vim.fn.readfile(path), { "foreign" }))
  assert(not vim.bo.modified)
  assert(vim.b.__fs_reconcile__ ~= nil)
end)
