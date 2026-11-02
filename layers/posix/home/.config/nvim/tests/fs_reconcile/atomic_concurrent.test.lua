local T = require "tests.lib"

T.test({ "atomic concurrent", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  local temporary = path .. ".agent"
  vim.fn.writefile({ "agent" }, temporary)
  assert(vim.uv.fs_rename(temporary, path))

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local" })
      and vim.deep_equal(vim.fn.readfile(path), { "local" })
      and not vim.bo.modified
  end, {
    timeout = 650,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })

  vim.cmd [[write!]]
  assert(vim.deep_equal(vim.fn.readfile(path), { "local" }))
  assert(not vim.bo.modified)
end)
