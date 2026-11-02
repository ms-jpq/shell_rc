local T = require "tests.lib"

T.test({ "refresh visibility and detach preserve one live watcher" }, function()
  local async = require "goto.async"
  local util = require "goto.fs_reconcile.util"
  local watchers = {}
  T.patch(util, "poller", function(path, interval, wake)
    local watcher = { path = path, interval = interval, wake = wake, closes = 0 }
    table.insert(watchers, watcher)
    return {
      close = function()
        watcher.closes = watcher.closes + 1
      end,
    }
  end)
  local path = T.file { "dogs" }
  vim.cmd.edit(path)
  local buf = vim.api.nvim_get_current_buf()
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds("VimEnter", {})
  T.eq(1, #watchers)
  vim.api.nvim_exec_autocmds("BufFilePost", { buffer = buf })
  vim.cmd.enew()
  vim.cmd.buffer(buf)
  T.eq(1, #watchers)
  T.eq(0, watchers[1].closes)
  local renamed = T.file { "small dogs" }
  vim.api.nvim_buf_set_name(buf, renamed)
  T.eq(2, #watchers)
  T.eq(1, watchers[1].closes)
  watchers[1].wake()
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, true), { "small dogs" })
  end)
  T.eq({ "dogs" }, vim.fn.readfile(path))
  vim.api.nvim_buf_delete(buf, { force = true })
  T.eq(1, watchers[2].closes)
  watchers[1].wake()
  watchers[2].wake()
  async.scheduled()
  assert(not vim.api.nvim_buf_is_valid(buf))
  T.eq({ "small dogs" }, vim.fn.readfile(renamed))
end)
