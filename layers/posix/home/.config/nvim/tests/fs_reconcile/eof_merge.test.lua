local T = require "tests.lib"

T.test({ "local deletion wins over a repeated remote append", timeout = 10000 }, function()
  local path = T.file { "a" }
  vim.cmd.edit(path)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "" })
  vim.fn.writefile({ "a", "a" }, path)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "" })
      and vim.deep_equal(vim.fn.readfile(path), { "" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })

  local changedtick = vim.api.nvim_buf_get_changedtick(0)
  require("goto.async").sleep(500)
  assert(changedtick == vim.api.nvim_buf_get_changedtick(0))
end)
