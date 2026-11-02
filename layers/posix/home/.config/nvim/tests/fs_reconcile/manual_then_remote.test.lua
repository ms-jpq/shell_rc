local T = require "tests.lib"

T.test({ "manual then remote", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "user" })
  vim.cmd.write()
  assert(vim.deep_equal(vim.fn.readfile(path), { "user" }) and not vim.bo.modified)

  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and vim.deep_equal(vim.fn.readfile(path), { "agent" })
      and not vim.bo.modified
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })
end)
