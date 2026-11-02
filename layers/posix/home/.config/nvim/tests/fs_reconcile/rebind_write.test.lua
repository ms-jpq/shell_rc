local T = require "tests.lib"

T.test({ "rebind write", timeout = 10000 }, function()
  local before, after = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "before" }, before)
  vim.fn.writefile({ "after" }, after)
  vim.cmd.edit(before)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd.file(after)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "after" })
      and vim.deep_equal(vim.fn.readfile(after), { "after" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect { disk = vim.fn.readfile(after), modified = vim.bo.modified }
    end,
  })

  local writes = 0
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd [[write!]]

  assert(vim.deep_equal(vim.fn.readfile(after), { "local" }))
  assert(writes == 1, vim.inspect { writes = writes })
end)
