local T = require "tests.lib"

T.test({ "event sources", timeout = 10000 }, function()
  local async = require "goto.async"
  local queue = require "goto.queue"
  local mpsc = queue.mpsc
  local events = {}
  T.patch(queue, "mpsc", function()
    local channel = mpsc()
    local send = channel.send
    T.patch(channel, "send", function(event)
      table.insert(events, event.type)
      return send(event)
    end)
    return channel
  end)

  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)
  events = {}

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  T.eventually(function()
    return #events > 0
  end, { timeout = 200 })

  local local_events = 0
  for _, event in pairs(events) do
    if event == "local" then
      local_events = local_events + 1
    end
  end
  assert(local_events == 1, vim.inspect(events))
end)
