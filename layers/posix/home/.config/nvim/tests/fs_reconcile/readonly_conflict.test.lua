local T = require "tests.lib"

T.test({ "readonly conflict", timeout = 10000 }, function()
  local path = T.file { "a" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local writes = 0
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "b" })
  vim.bo.readonly = true
  vim.fn.writefile({ "c" }, path)
  require("goto.async").sleep(1000)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "b" })
      and vim.deep_equal(vim.fn.readfile(path), { "c" })
      and vim.bo.modified
      and writes == 0
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
        writes = writes,
      }
    end,
  })

  vim.bo.readonly = false
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "b" }) and not vim.bo.modified and writes == 1
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path), modified = vim.bo.modified, writes = writes }
    end,
  })
end)
