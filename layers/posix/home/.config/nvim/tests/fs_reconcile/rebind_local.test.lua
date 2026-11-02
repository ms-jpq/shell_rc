local T = require "tests.lib"

T.test({ "rebind local", timeout = 10000 }, function()
  local before, after = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "base" }, before)
  vim.cmd.edit(before)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.file(after)
  local state = function()
    return vim.inspect {
      disk = vim.uv.fs_stat(after) and vim.fn.readfile(after) or nil,
    }
  end
  T.eventually(function()
    return vim.uv.fs_stat(after) ~= nil and vim.deep_equal(vim.fn.readfile(after), { "local" }) and not vim.bo.modified
  end, {
    message = function()
      return state()
    end,
  })
end)
