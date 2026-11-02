local T = require "tests.lib"

T.test({ "foreign write command global", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    pattern = "*",
    callback = function(args)
      vim.fn.writefile({ "foreign" }, args.file)
      vim.bo[args.buf].modified = false
    end,
  })

  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  assert(vim.b.__fs_reconcile__ ~= nil)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.write()
  assert(vim.deep_equal(vim.fn.readfile(path), { "foreign" }))
  assert(not vim.bo.modified)
end)
