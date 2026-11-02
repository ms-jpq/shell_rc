local T = require "tests.lib"

T.test({ "isolation", timeout = 10000 }, function()
  local first, second = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "one" }, first)
  vim.fn.writefile({ "two" }, second)
  vim.cmd.edit(first)
  local first_buf = vim.api.nvim_get_current_buf()
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd.edit(second)
  local second_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(second_buf, 0, -1, true, { "local two" })
  vim.fn.writefile({ "agent one" }, first)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(first_buf, 0, -1, true), { "agent one" })
      and vim.deep_equal(vim.fn.readfile(second), { "local two" })
      and not vim.bo[first_buf].modified
      and not vim.bo[second_buf].modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        first = vim.api.nvim_buf_get_lines(first_buf, 0, -1, true),
        second = vim.api.nvim_buf_get_lines(second_buf, 0, -1, true),
        disk = vim.fn.readfile(second),
        modified = vim.bo[second_buf].modified,
      }
    end,
  })
end)
