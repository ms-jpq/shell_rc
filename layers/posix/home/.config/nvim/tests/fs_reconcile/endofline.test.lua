local T = require "tests.lib"

T.test({ "endofline", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "base", 0))
  assert(vim.uv.fs_close(fd))
  vim.cmd.edit(path)
  assert(not vim.bo.endofline)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "agent\n", 0))
  assert(vim.uv.fs_close(fd))

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and vim.bo.endofline
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        endofline = vim.bo.endofline,
      }
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "saved" })
  T.eventually(function()
    return vim.fn.readblob(path) == "saved\n" and not vim.bo.modified
  end)
end)
