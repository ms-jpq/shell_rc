local T = require "tests.lib"

T.test({ "line endings", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "agent\r\nsecond\r\n", 0))
  assert(vim.uv.fs_close(fd))

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent", "second" })
      and vim.bo.fileformat == "unix"
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        fileformat = vim.bo.fileformat,
      }
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "saved" })
  T.eventually(function()
    return vim.fn.readblob(path) == "saved\nsecond\n" and not vim.bo.modified
  end)
end)
