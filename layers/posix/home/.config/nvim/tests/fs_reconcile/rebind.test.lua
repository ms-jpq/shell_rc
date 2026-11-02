local T = require "tests.lib"

T.test({ "rebind", timeout = 10000 }, function()
  local root = vim.fn.tempname()
  local before, after = root .. "/before", root .. "/after"
  assert(vim.uv.fs_mkdir(root, 493))
  vim.fn.writefile({ "before" }, before)
  vim.cmd.edit(before)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd.saveas(after)
  vim.fn.writefile({ "after" }, after)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "after" })
      and vim.deep_equal(vim.fn.readfile(after), { "after" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(after),
        channel = vim.b[0].__fs_reconcile__ ~= nil,
      }
    end,
  })
end)
