local T = require "tests.lib"

T.test({ "no endofline", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local write = function(text)
    local fd = assert(vim.uv.fs_open(path, "w", 420))
    assert(vim.uv.fs_write(fd, text, 0))
    assert(vim.uv.fs_close(fd))
  end

  write "base"
  vim.cmd.edit(path)
  assert(not vim.bo.endofline)
  assert(vim.bo.fixendofline)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  T.eventually(function()
    return vim.fn.readblob(path) == "local" and not vim.bo.endofline and vim.bo.fixendofline and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        endofline = vim.bo.endofline,
        disk = vim.fn.readblob(path),
        fixendofline = vim.bo.fixendofline,
        modified = vim.bo.modified,
      }
    end,
  })

  write "agent"
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and not vim.bo.endofline
      and vim.bo.fixendofline
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        endofline = vim.bo.endofline,
        disk = vim.fn.readblob(path),
        fixendofline = vim.bo.fixendofline,
        modified = vim.bo.modified,
      }
    end,
  })
end)
