local T = require "tests.lib"

T.test({ "write pre remote", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = 0,
    once = true,
    callback = function()
      vim.fn.writefile({ "agent" }, path)
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local" })
      and vim.deep_equal(vim.fn.readfile(path), { "local" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
      }
    end,
  })

  vim.cmd [[write!]]
  assert(vim.deep_equal(vim.fn.readfile(path), { "local" }))
  assert(not vim.bo.modified)
end)
