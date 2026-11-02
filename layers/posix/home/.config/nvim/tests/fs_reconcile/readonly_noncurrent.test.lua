local T = require "tests.lib"

T.test({ "readonly noncurrent", timeout = 10000 }, function()
  vim.o.hidden = true

  local first, second = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "first" }, first)
  vim.fn.writefile({ "a" }, second)
  vim.cmd.edit(first)
  local first_buf = vim.api.nvim_get_current_buf()
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd.edit(second)
  local second_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(second_buf, 0, -1, true, { "b" })
  vim.cmd.edit(first)
  vim.bo[second_buf].readonly = true
  vim.fn.writefile({ "c" }, second)
  require("goto.async").sleep(1000)

  T.eventually(function()
    return vim.api.nvim_get_current_buf() == first_buf
      and vim.deep_equal(vim.api.nvim_buf_get_lines(second_buf, 0, -1, true), { "b" })
      and vim.deep_equal(vim.fn.readfile(second), { "c" })
      and vim.bo[second_buf].modified
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect {
        current = vim.api.nvim_get_current_buf(),
        buffer = vim.api.nvim_buf_get_lines(second_buf, 0, -1, true),
        disk = vim.fn.readfile(second),
        modified = vim.bo[second_buf].modified,
      }
    end,
  })

  vim.bo[second_buf].readonly = false
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(second), { "b" }) and not vim.bo[second_buf].modified
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect {
        current = vim.api.nvim_get_current_buf(),
        buffer = vim.api.nvim_buf_get_lines(second_buf, 0, -1, true),
        disk = vim.fn.readfile(second),
        modified = vim.bo[second_buf].modified,
      }
    end,
  })
end)
