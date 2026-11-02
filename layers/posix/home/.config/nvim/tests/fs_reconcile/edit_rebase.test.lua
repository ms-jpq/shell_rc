local T = require "tests.lib"

T.test({ "edit rebase", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.fn.writefile({ "reloaded" }, path)
  vim.cmd("edit! " .. vim.fn.fnameescape(path))
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "reloaded" }))
  assert(not vim.bo.modified)

  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.modified
  end)
end)
