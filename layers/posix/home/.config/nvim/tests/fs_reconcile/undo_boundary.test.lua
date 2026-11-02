local T = require "tests.lib"

T.test({ "undo boundary", timeout = 10000 }, function()
  local apply = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"

  local global_undolevels = function()
    return vim.api.nvim_get_option_value("undolevels", { scope = "global" })
  end

  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "base" })
  vim.o.undolevels = 1000
  vim.opt_local.undolevels = 2000

  local run = function(text)
    local current = util.buffer(buf)
    local replacement = apply.plan(current, { text = string.sub(text, 1, -2), endofline = true })
    apply.apply(buf, replacement, function() end)
  end

  local get_mode = vim.api.nvim_get_mode
  T.patch(vim.api, "nvim_get_mode", function()
    return { mode = "i" }
  end)
  run "insert\n"
  vim.api.nvim_get_mode = get_mode

  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, true), { "insert" }))
  assert(global_undolevels() == 1000)
  assert(vim.bo[buf].undolevels == 2000)

  run "normal\n"
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, true), { "normal" }))
  assert(global_undolevels() == 1000)
  assert(vim.bo[buf].undolevels == 2000)
end)
