local T = require "tests.lib"

T.test({ "opaque", timeout = 10000 }, function()
  local path = T.file { "a", "b" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, string.rep("x", 2 * 1024 * 1024 + 1), 0))
  assert(vim.uv.fs_close(fd))
  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "local" })

  require("goto.async").sleep(1000)
  T.eventually(function()
    return vim.bo.modified and assert(vim.uv.fs_stat(path)).size > 2 * 1024 * 1024
  end, {
    timeout = 500,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = assert(vim.uv.fs_stat(path)).size,
      }
    end,
  })

  vim.fn.writefile({ "a", "agent" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local", "agent" })
      and vim.deep_equal(vim.fn.readfile(path), { "local", "agent" })
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

  assert(vim.deep_equal(vim.fn.readfile(path), { "local", "agent" }))
  assert(not vim.bo.modified)
end)
