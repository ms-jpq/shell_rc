local T = require "tests.lib"

T.test({ "post write concurrent", timeout = 10000 }, function()
  local path = T.file { "a", "b", "c" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})

  local injected = false
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = 0,
    once = true,
    callback = function()
      injected = true
      assert(vim.deep_equal(vim.fn.readfile(path), { "a", "local", "b", "c" }))
      vim.fn.writefile({ "a", "local", "B", "c" }, path)
      vim.api.nvim_buf_set_lines(0, 3, 4, true, { "C" })
    end,
  })
  vim.api.nvim_buf_set_lines(0, 1, 1, true, { "local" })

  T.eventually(function()
    return injected
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "a", "local", "B", "C" })
      and vim.deep_equal(vim.fn.readfile(path), { "a", "local", "B", "C" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect { buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true), disk = vim.fn.readfile(path) }
    end,
  })
end)
