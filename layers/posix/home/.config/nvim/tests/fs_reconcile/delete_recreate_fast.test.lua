local T = require "tests.lib"

T.test({ "delete recreate fast", timeout = 10000 }, function()
  local path = T.file { "a", "b", "c" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "A" })
  assert(vim.uv.fs_unlink(path))
  require("goto.async").sleep(10)
  vim.fn.writefile({ "a", "B", "c" }, path)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "A", "B", "c" })
      and vim.deep_equal(vim.fn.readfile(path), { "a", "B", "c" })
      and vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.uv.fs_stat(path) and vim.fn.readfile(path) or nil,
        modified = vim.bo.modified,
      }
    end,
  })

  vim.cmd [[write!]]
  assert(vim.deep_equal(vim.fn.readfile(path), { "A", "B", "c" }))
  assert(not vim.bo.modified)
end)
