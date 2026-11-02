local T = require "tests.lib"

T.test({ "modifiable noncurrent", timeout = 10000 }, function()
  vim.o.hidden = true

  local first, second = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "first" }, first)
  vim.fn.writefile({ "second" }, second)
  vim.cmd.edit(first)
  local first_buf = vim.api.nvim_get_current_buf()
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd.edit(second)
  local second_buf = vim.api.nvim_get_current_buf()
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)
  vim.cmd.edit(first)

  vim.api.nvim_buf_call(second_buf, function()
    vim.cmd [[setlocal nomodifiable]]
  end)
  vim.fn.writefile({ "agent second" }, second)
  require("goto.async").sleep(1000)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(second_buf, 0, -1, true), { "second" }))
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(first_buf, 0, -1, true), { "first" }))

  vim.api.nvim_buf_call(second_buf, function()
    vim.cmd [[setlocal modifiable]]
  end)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(second_buf, 0, -1, true), { "agent second" })
      and vim.deep_equal(vim.api.nvim_buf_get_lines(first_buf, 0, -1, true), { "first" })
      and vim.api.nvim_get_current_buf() == first_buf
  end, {
    message = function()
      return vim.inspect {
        current = vim.api.nvim_get_current_buf(),
        first = vim.api.nvim_buf_get_lines(first_buf, 0, -1, true),
        second = vim.api.nvim_buf_get_lines(second_buf, 0, -1, true),
        attached = vim.b[second_buf].__fs_reconcile__ ~= nil,
        modifiable = vim.bo[second_buf].modifiable,
      }
    end,
  })
end)
