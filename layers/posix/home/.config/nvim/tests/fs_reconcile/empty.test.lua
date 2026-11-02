local T = require "tests.lib"

T.test({ "empty", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "\n", 0))
  assert(vim.uv.fs_close(fd))

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "" })
      and vim.bo.endofline
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        modified = vim.bo.modified,
      }
    end,
  })

  fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "", 0))
  assert(vim.uv.fs_close(fd))

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "" })
      and not vim.bo.endofline
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        endofline = vim.bo.endofline,
        modified = vim.bo.modified,
      }
    end,
  })

  require("goto.async").sleep(1000)
  assert(vim.fn.readblob(path) == "")
end)
