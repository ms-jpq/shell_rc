local T = require "tests.lib"

T.test({ "multiline conflict", timeout = 10000 }, function()
  local path = T.file { "a", "b", "c", "d" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  local expected = { "a", "local-1", "local-2", "d" }
  vim.api.nvim_buf_set_lines(0, 1, 3, true, { "local-1", "local-2" })
  vim.fn.writefile({ "a", "remote-1", "remote-2", "d" }, path)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected)
      and vim.deep_equal(vim.fn.readfile(path), expected)
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

  vim.cmd [[write!]]
  assert(vim.deep_equal(vim.fn.readfile(path), expected))
  assert(not vim.bo.modified)
end)
