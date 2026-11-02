local T = require "tests.lib"

T.test({ "unload recover", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local buf = vim.api.nvim_get_current_buf()
  assert(vim.b[buf].__fs_reconcile__ ~= nil)
  vim.cmd.enew()
  vim.cmd("bunload " .. buf)
  assert(vim.b[buf].__fs_reconcile__ == nil)

  vim.fn.writefile({ "agent" }, path)
  vim.cmd("buffer " .. buf)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, true), { "agent" })
      and not vim.bo[buf].modified
      and vim.b[buf].__fs_reconcile__ ~= nil
  end)
end)
