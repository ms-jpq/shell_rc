local T = require "tests.lib"

T.test({ "bom", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "\239\187\191agent\n", 0))
  assert(vim.uv.fs_close(fd))

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.bomb
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        bomb = vim.bo.bomb,
      }
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "saved" })
  T.eventually(function()
    return vim.fn.readblob(path) == "saved\n" and not vim.bo.modified
  end)

  fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "plain\n", 0))
  assert(vim.uv.fs_close(fd))
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "plain" })
      and not vim.bo.bomb
      and not vim.bo.modified
  end)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "saved again" })
  T.eventually(function()
    return vim.fn.readblob(path) == "saved again\n" and not vim.bo.modified
  end)
end)
