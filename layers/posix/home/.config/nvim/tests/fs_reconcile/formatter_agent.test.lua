local T = require "tests.lib"

T.test({ "formatter agent", timeout = 10000 }, function()
  local path = T.file { "dog one", "dog two" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local pre, writes = 0, 0
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      pre = pre + 1
      if pre == 1 then
        vim.api.nvim_buf_set_lines(0, 0, -1, true, { "USER ONE", "DOG TWO" })
        vim.fn.writefile({ "dog one", "AGENT TWO" }, path)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "user one" })

  local expected = { "USER ONE", "DOG TWO" }
  T.eventually(function()
    return pre == 2
      and writes == 1
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected)
      and vim.deep_equal(vim.fn.readfile(path), expected)
      and not vim.bo.modified
  end, {
    timeout = 4000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        pre = pre,
        writes = writes,
      }
    end,
  })
end)
