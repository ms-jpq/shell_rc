local T = require "tests.lib"

T.test({ "background formatter", timeout = 10000 }, function()
  local first, second = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "first" }, first)
  vim.fn.writefile({ "second" }, second)
  vim.cmd.edit(first)
  local first_buf = vim.api.nvim_get_current_buf()
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd.edit(second)
  local second_buf = vim.api.nvim_get_current_buf()
  vim.cmd.edit(first)

  local seen
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = second_buf,
    once = true,
    callback = function()
      seen = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_lines(0, 0, -1, true, { "formatted second" })
    end,
  })

  vim.api.nvim_buf_set_lines(second_buf, 0, -1, true, { "local second" })

  T.eventually(function()
    return seen == second_buf
      and vim.api.nvim_get_current_buf() == first_buf
      and vim.deep_equal(vim.api.nvim_buf_get_lines(first_buf, 0, -1, true), { "first" })
      and vim.deep_equal(vim.fn.readfile(first), { "first" })
      and vim.deep_equal(vim.api.nvim_buf_get_lines(second_buf, 0, -1, true), { "formatted second" })
      and vim.deep_equal(vim.fn.readfile(second), { "formatted second" })
      and not vim.bo[first_buf].modified
      and not vim.bo[second_buf].modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        current = vim.api.nvim_get_current_buf(),
        first = vim.api.nvim_buf_get_lines(first_buf, 0, -1, true),
        first_disk = vim.fn.readfile(first),
        second = vim.api.nvim_buf_get_lines(second_buf, 0, -1, true),
        second_disk = vim.fn.readfile(second),
        seen = seen,
      }
    end,
  })
end)
