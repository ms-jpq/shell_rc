local T = require "tests.lib"

T.test({ "endoffile write", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "base\r\n", 0))
  assert(vim.uv.fs_close(fd))
  vim.cmd.edit(path)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  vim.cmd [[setlocal nofixendofline noendofline endoffile]]
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })

  T.eventually(function()
    return not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        blob = vim.fn.readblob(path),
        lines = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        modified = vim.bo.modified,
      }
    end,
  })
  assert(
    vim.fn.readblob(path) == "local\026",
    vim.inspect {
      text = vim.fn.readblob(path),
      format = vim.bo.fileformat,
      endofline = vim.bo.endofline,
      endoffile = vim.bo.endoffile,
    }
  )
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local" }))
end)
