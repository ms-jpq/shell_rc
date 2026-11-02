local T = require "tests.lib"

T.test({ "delete recreate dirty", timeout = 10000 }, function()
  local path = T.file { "dog one", "dog two" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "user one" })
  assert(vim.uv.fs_unlink(path))

  T.eventually(function()
    return not vim.uv.fs_stat(path) and vim.bo.modified
  end, {
    timeout = 1500,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.uv.fs_stat(path),
        modified = vim.bo.modified,
      }
    end,
  })

  vim.fn.writefile({ "dog one", "agent two" }, path)
  local expected = { "user one", "agent two" }
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected)
      and vim.deep_equal(vim.fn.readfile(path), { "dog one", "agent two" })
      and vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })

  vim.cmd [[write!]]
  assert(vim.deep_equal(vim.fn.readfile(path), expected))
  assert(not vim.bo.modified)
end)
