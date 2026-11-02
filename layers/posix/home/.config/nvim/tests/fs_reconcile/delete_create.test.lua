local T = require "tests.lib"

T.test({ "delete create", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  assert(vim.uv.fs_unlink(path))
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "" }) and not vim.bo.modified
  end)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  T.eventually(function()
    return vim.uv.fs_stat(path) ~= nil and vim.deep_equal(vim.fn.readfile(path), { "local" }) and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path) }
    end,
  })
end)
