local T = require "tests.lib"

T.test({ "hunk mark failure", timeout = 10000 }, function()
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"

  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "a", "b", "c" })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  local replacement = hunks.plan(util.buffer(buf), { text = "A\nb\nC", endofline = false })
  local ok = pcall(hunks.apply, buf, replacement, function()
    error "highlight failed"
  end)

  assert(not ok)
  local ns = vim.api.nvim_create_namespace "fs-reconcile-cursor"
  assert(#vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) == 0)
end)
