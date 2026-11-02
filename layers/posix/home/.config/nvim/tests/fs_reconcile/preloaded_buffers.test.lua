local T = require "tests.lib"

T.test({ "preloaded buffers", timeout = 10000 }, function()
  local first = vim.fn.tempname()
  local second = vim.fn.tempname()
  vim.fn.writefile({ "first" }, first)
  vim.fn.writefile({ "second" }, second)
  vim.cmd.edit(first)

  local second_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(second_buf, second)
  vim.api.nvim_buf_set_lines(second_buf, 0, -1, true, { "second" })

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  T.eventually(function()
    return vim.b[0].__fs_reconcile__ ~= nil and vim.b[second_buf].__fs_reconcile__ ~= nil
  end, { timeout = 1000 })

  vim.fn.writefile({ "agent" }, second)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(second_buf, 0, -1, true), { "agent" })
      and not vim.bo[second_buf].modified
  end)
end)
