local T = require "tests.lib"

T.test({ "post write insertion", timeout = 10000 }, function()
  local path = T.file { "a", "b" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})

  local injected = false
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = 0,
    once = true,
    callback = function()
      injected = true
      assert(vim.deep_equal(vim.fn.readfile(path), { "a", "local", "b" }))
      vim.fn.writefile({ "a", "local", "B" }, path)
    end,
  })
  vim.api.nvim_buf_set_lines(0, 1, 1, true, { "local" })

  T.eventually(function()
    return injected
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "a", "local", "B" })
      and vim.deep_equal(vim.fn.readfile(path), { "a", "local", "B" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect { buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true), disk = vim.fn.readfile(path) }
    end,
  })
end)
