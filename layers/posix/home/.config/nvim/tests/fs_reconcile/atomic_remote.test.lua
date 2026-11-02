local T = require "tests.lib"

T.test({ "atomic remote", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local temporary = path .. ".agent"
  vim.fn.writefile({ "agent" }, temporary)
  assert(vim.uv.fs_rename(temporary, path))

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
      }
    end,
  })
end)
