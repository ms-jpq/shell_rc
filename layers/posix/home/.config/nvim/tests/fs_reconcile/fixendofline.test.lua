local T = require "tests.lib"

T.test({ "fixendofline", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "base", 0))
  assert(vim.uv.fs_close(fd))
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  vim.bo.fixendofline = false
  vim.api.nvim_exec_autocmds({ "OptionSet" }, { pattern = "fixendofline" })
  vim.bo.fixendofline = true
  vim.api.nvim_exec_autocmds({ "OptionSet" }, { pattern = "fixendofline" })

  T.eventually(function()
    return vim.fn.readblob(path) == "base" and vim.bo.fixendofline and not vim.bo.modified
  end)
end)
