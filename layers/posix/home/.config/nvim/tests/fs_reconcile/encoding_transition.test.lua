local T = require "tests.lib"

T.test({ "encoding transition", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  vim.cmd.edit(path)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "café", "before" })
  vim.bo.fileencoding = "latin1"
  vim.cmd.write()

  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  local bytes = vim.fn.readblob(path)
  local version = vim.uv.fs_stat(path)

  vim.bo.fileencoding = "utf-8"
  assert(vim.fn.readblob(path) == bytes)
  assert(require("goto.fs_reconcile.util").same_version(version, vim.uv.fs_stat(path)))
  vim.api.nvim_buf_set_lines(0, 1, 2, true, { "after" })

  T.eventually(function()
    return vim.fn.readblob(path) == "café\nafter\n" and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect { bytes = { string.byte(vim.fn.readblob(path), 1, -1) }, modified = vim.bo.modified }
    end,
  })
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  assert(vim.deep_equal(lines, { "café", "after" }), vim.inspect { buffer = lines })
end)
