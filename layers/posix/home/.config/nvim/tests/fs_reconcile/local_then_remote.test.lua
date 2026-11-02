local T = require "tests.lib"

T.test({ "local then remote", timeout = 10000 }, function()
  local path = T.file { "dog one", "dog two" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "user one" })
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "user one", "dog two" }) and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect { buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true), disk = vim.fn.readfile(path) }
    end,
  })

  vim.fn.writefile({ "user one", "agent two" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "user one", "agent two" })
      and not vim.bo.modified
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect { buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true), disk = vim.fn.readfile(path) }
    end,
  })
end)
