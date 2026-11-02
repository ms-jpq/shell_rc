local T = require "tests.lib"

T.test({ "mpsc order", timeout = 10000 }, function()
  local async = require "goto.async"
  local queue = require "goto.queue"
  local chan = queue.mpsc()
  vim.schedule(function()
    chan.send "event"
  end)
  assert(not chan.wait(0))
  assert(chan() == "event")
  chan.close()

  local timeout = queue.mpsc()
  assert(timeout.wait(0))
  timeout.close()

  local defer_fn = vim.defer_fn
  local schedule = vim.schedule

  local race = function(wake, wake_first)
    local deferred, scheduled = {}, {}
    T.patch(vim, "defer_fn", function(callback)
      table.insert(deferred, callback)
      return {
        is_closing = function()
          return false
        end,
        close = function() end,
      }
    end)
    T.patch(vim, "schedule", function(callback)
      table.insert(scheduled, callback)
    end)

    local chan = queue.mpsc()
    local elapsed
    async.run(function()
      elapsed = chan.wait(0)
    end)
    assert(#deferred == 1)
    if wake_first then
      wake(chan)
      deferred[1]()
    else
      deferred[1]()
      wake(chan)
    end
    assert(#scheduled == 1)
    vim.defer_fn = defer_fn
    vim.schedule = schedule
    scheduled[1]()
    assert(elapsed == false)
    return chan
  end

  for _, wake_first in pairs { false, true } do
    local sent = race(function(chan)
      chan.send "boundary"
    end, wake_first)
    assert(sent() == "boundary")
  end

  for _, send_first in pairs { false, true } do
    local deferred, scheduled = {}, {}
    local closed = false
    T.patch(vim, "defer_fn", function(callback)
      table.insert(deferred, callback)
      return {
        is_closing = function()
          return closed
        end,
        close = function()
          closed = true
        end,
      }
    end)
    T.patch(vim, "schedule", function(callback)
      table.insert(scheduled, callback)
    end)

    local chan = queue.mpsc()
    local elapsed
    async.run(function()
      elapsed = chan.wait(100)
    end)
    if send_first then
      chan.send "discarded"
    end
    chan.close()
    assert(elapsed == false)
    assert(closed)
    assert(chan() == nil)
    vim.defer_fn = defer_fn
    vim.schedule = schedule
    for _, callback in pairs(scheduled) do
      callback()
    end
    deferred[1]()
  end
end)
