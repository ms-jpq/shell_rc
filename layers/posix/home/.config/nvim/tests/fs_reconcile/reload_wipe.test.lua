local T = require "tests.lib"

T.test({ "reload wipe", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local notifications = {}
  local notify = vim.notify
  T.patch(vim, "notify", function(message, level)
    table.insert(notifications, { message = message, level = level })
  end)

  vim.cmd [[edit!]]
  vim.cmd [[bwipeout!]]
  require("goto.async").sleep(100)
  vim.notify = notify

  assert(#notifications == 0, vim.inspect(notifications))
end)
