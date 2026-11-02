local T = require "tests.lib"

T.test({ "edit reload", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd [[edit!]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end, { timeout = 1000 })

  local writes = 0
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.write()
  assert(vim.deep_equal(vim.fn.readfile(path), { "local" }))
  assert(writes == 1, vim.inspect { writes = writes })

  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and not vim.bo.modified
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect {
        attached = vim.b.__fs_reconcile__ ~= nil,
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        writes = writes,
      }
    end,
  })
end)
