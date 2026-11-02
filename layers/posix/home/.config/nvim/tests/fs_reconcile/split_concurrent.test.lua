local T = require "tests.lib"

T.test({ "split concurrent", timeout = 10000 }, function()
  local path = T.file { "before", "dog runs", "after" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})

  vim.api.nvim_buf_set_lines(0, 1, 2, true, { "dog", "runs" })
  vim.fn.writefile({ "before", "dog walks", "after" }, path)
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })

  local expected = { "before", "dog", "walks", "after" }
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected)
      and vim.deep_equal(vim.fn.readfile(path), expected)
      and not vim.bo.modified
  end)

  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })
  require("goto.async").sleep(750)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected))
  assert(vim.deep_equal(vim.fn.readfile(path), expected))
  assert(not vim.bo.modified)
end)
