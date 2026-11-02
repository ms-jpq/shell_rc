local T = require "tests.lib"

T.test({ "rebind existing", timeout = 10000 }, function()
  local before, after = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "before" }, before)
  vim.fn.writefile({ "agent" }, after)
  vim.cmd.edit(before)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.file(after)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local", "agent" })
      and vim.deep_equal(vim.fn.readfile(after), { "agent" })
      and vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(after),
        modified = vim.bo.modified,
      }
    end,
  })

  vim.cmd [[write!]]
  assert(vim.deep_equal(vim.fn.readfile(after), { "local", "agent" }))
  assert(not vim.bo.modified)
end)
