local T = require "tests.lib"

T.test({ "hunks stale", timeout = 10000 }, function()
  local apply = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"

  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "base" })
  local current = util.buffer(buf)
  local replacement = apply.plan(current, { text = "remote", endofline = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "local" })

  assert(current.changedtick ~= vim.api.nvim_buf_get_changedtick(buf))
  assert(vim.deep_equal(replacement.changes, {
    { start = 0, finish = 1, records = { "remote\n" } },
  }))
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, true), { "local" }))
end)
