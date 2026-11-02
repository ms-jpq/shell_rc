local T = require "tests.lib"

T.test({ "a delayed writer preserves independent local edits", timeout = 10000 }, function()
  local path = T.file { "one", "two", "three" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "ONE" })
  vim.fn.writefile({ "one", "TWO" }, path)

  -- Keep writing within the remote quiet period; a completed quiet period is a
  -- separate observation, not an unfinished write.
  require("goto.async").sleep(100)
  T.eq({ "one", "TWO" }, vim.fn.readfile(path))
  vim.fn.writefile({ "one", "TWO", "THREE" }, path)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "ONE", "TWO", "THREE" })
      and vim.deep_equal(vim.fn.readfile(path), { "ONE", "TWO", "THREE" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })

  assert(vim.deep_equal(vim.fn.readfile(path), { "ONE", "TWO", "THREE" }))
  assert(not vim.bo.modified)
end)
