local T = require "tests.lib"

T.test({ "remote edits reload clean buffers", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.fn.writefile({ "remote" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "remote" })
  end, {
    message = function()
      return vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end,
  })
  local ns = vim.api.nvim_create_namespace "fs-reconcile"
  assert(#vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) > 0)
end)
