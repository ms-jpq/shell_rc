local T = require "tests.lib"

T.test({ "encoding write hooks", timeout = 10000 }, function()
  local path = T.file { "café", "before" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})

  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    once = true,
    callback = function()
      vim.bo.fileencoding = "latin1"
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = 0,
    once = true,
    callback = function()
      vim.bo.fileencoding = "utf-8"
    end,
  })
  vim.api.nvim_buf_set_lines(0, 1, 2, true, { "after" })
  T.eventually(function()
    return vim.fn.readblob(path) == "caf\233\nafter\n" and vim.bo.fileencoding == "utf-8"
  end)

  vim.api.nvim_buf_set_lines(0, 1, 2, true, { "again" })
  T.eventually(function()
    return vim.fn.readblob(path) == "café\nagain\n" and not vim.bo.modified
  end)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "café", "again" }))
end)
