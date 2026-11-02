local T = require "tests.lib"

T.test({ "hunks empty", timeout = 10000 }, function()
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"

  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "" })

  local replacement = hunks.plan(util.buffer(buf), { text = "dog\ncat", endofline = true })
  assert(
    vim.deep_equal(replacement.changes, {
      { start = 0, finish = 1, records = { "dog\n", "cat\n" } },
    }),
    vim.inspect(replacement.changes)
  )

  hunks.apply(buf, replacement, function() end)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, true), { "dog", "cat" }))
  assert(vim.bo[buf].endofline)
end)
