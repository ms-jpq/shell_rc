local T = require "tests.lib"

T.test({ "rebind gap", timeout = 10000 }, function()
  local before, after = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "before" }, before)
  vim.fn.writefile({ "base" }, after)
  vim.cmd.edit(before)

  local once = true
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  vim.api.nvim_create_autocmd({ "BufFilePost" }, {
    callback = function()
      if once then
        once = false
        vim.fn.writefile({ "agent" }, after)
      end
    end,
  })
  vim.cmd.file(after)

  assert(not once)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and vim.deep_equal(vim.fn.readfile(after), { "agent" })
      and not vim.bo.modified
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(after),
        modified = vim.bo.modified,
      }
    end,
  })
end)
