local T = require "tests.lib"

T.test({ "foreign write command pattern", timeout = 10000 }, function()
  local path = vim.fn.tempname() .. ".txt"
  vim.fn.writefile({ "base" }, path)
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    pattern = { "*.foo" },
    callback = function()
      error "must not run"
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.write()
  assert(vim.deep_equal(vim.fn.readfile(path), { "local" }))
  assert(not vim.bo.modified)
end)
