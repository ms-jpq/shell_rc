local T = require "tests.lib"

T.test({ "alternate write", timeout = 10000 }, function()
  local source, target = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "base" }, source)
  vim.cmd.edit(source)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd("write! " .. vim.fn.fnameescape(target))

  assert(vim.deep_equal(vim.fn.readfile(source), { "base" }))
  assert(vim.deep_equal(vim.fn.readfile(target), { "local" }))
  assert(vim.bo.modified)
end)
