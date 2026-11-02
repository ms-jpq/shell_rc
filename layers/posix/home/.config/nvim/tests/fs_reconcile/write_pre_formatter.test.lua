local T = require "tests.lib"

T.test({ "write pre formatter", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local formatted = false
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      if not formatted then
        formatted = true
        vim.api.nvim_buf_set_lines(0, 0, -1, true, { "formatted" })
      end
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })

  T.eventually(function()
    return formatted
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "formatted" })
      and vim.deep_equal(vim.fn.readfile(path), { "formatted" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        formatted = formatted,
      }
    end,
  })
end)
