local T = require "tests.lib"

T.test({ "nonwhole write", timeout = 10000 }, function()
  local path = T.file { "one", "two" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "one", "local" })

  vim.cmd [[1,1write! %]]
  assert(vim.deep_equal(vim.fn.readfile(path), { "one" }))
  assert(vim.bo.modified)

  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "one", "local" })
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "one", "local" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path), modified = vim.bo.modified }
    end,
  })

  vim.api.nvim_buf_set_lines(0, 1, 2, true, { "later" })
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "one", "later" }) and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path), modified = vim.bo.modified }
    end,
  })

  vim.api.nvim_buf_set_lines(0, 1, 2, true, { "append" })
  vim.cmd [[write! >> %]]
  assert(vim.deep_equal(vim.fn.readfile(path), { "one", "later", "one", "append" }))
  assert(vim.bo.modified)

  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "one", "append", "one", "append" })
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "one", "append", "one", "append" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path), modified = vim.bo.modified }
    end,
  })

  vim.api.nvim_buf_set_lines(0, 1, 2, true, { "after-append" })
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "one", "after-append", "one", "append" })
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "one", "after-append", "one", "append" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path), modified = vim.bo.modified }
    end,
  })
end)
