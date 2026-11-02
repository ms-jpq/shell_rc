local T = require "tests.lib"

T.test({ "representation converged", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd [[setlocal fileformat=dos]]
  vim.api.nvim_exec_autocmds("OptionSet", { pattern = "fileformat" })
  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "base\r\n", 0))
  assert(vim.uv.fs_close(fd))

  T.eventually(function()
    return vim.fn.readblob(path) == "base\r\n" and not vim.bo.modified
  end)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  T.eventually(function()
    return vim.fn.readblob(path) == "local\r\n" and not vim.bo.modified
  end)
end)
