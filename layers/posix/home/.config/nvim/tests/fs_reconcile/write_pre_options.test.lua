local T = require "tests.lib"

T.test({ "write pre options", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    once = true,
    callback = function()
      vim.bo.endofline = false
      vim.bo.readonly = true
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.write()

  assert(vim.fn.readblob(path) == "local\n")
  assert(not vim.bo.endofline)
  assert(vim.bo.readonly)
  assert(not vim.bo.modified)
end)
