local async = require "goto.async"

local M = {}

---@generic T
---@class QueueMpsc<T>
---@field close fun()
---@field send fun(value: T): boolean
---@field wait fun(milliseconds: integer): boolean
---@operator call: fun(...: any): T?

---@generic T
---@return QueueMpsc<T>
M.mpsc = function()
  local closed = false
  local values = {}
  local pending ---@type { elapsed: boolean, resolve: fun(elapsed: boolean), scheduled: boolean }?

  local notify = function(elapsed)
    if pending then
      pending.elapsed = elapsed
      if not pending.scheduled then
        local waiter = pending
        waiter.scheduled = true
        vim.schedule(function()
          if pending == waiter then
            pending = nil
            waiter.resolve(waiter.elapsed)
          end
        end)
      end
    end
  end

  local await = function()
    assert(not pending, "mpsc: consumer already waiting")
    local future = async.future()
    pending = { elapsed = false, resolve = future.resolve, scheduled = false }
    return future
  end

  local ch = {}

  ch.close = function()
    if closed then
      return
    end
    closed = true
    values = {}
    notify(false)
  end

  ch.send = function(value)
    assert(value ~= nil, "mpsc: nil message")
    if closed then
      return false
    end
    table.insert(values, value)
    notify(false)
    return true
  end

  ch.wait = function(milliseconds)
    if closed or #values > 0 then
      return false
    end
    local future = await()
    local waiter = pending
    vim.defer_fn(function()
      if pending == waiter then
        notify(true)
      end
    end, milliseconds)
    local elapsed = future.await()
    return not closed and elapsed == true
  end

  local next = function()
    if closed then
      return
    elseif #values > 0 then
      return table.remove(values, 1)
    end
    local future = await()
    future.await()
    if not closed then
      return table.remove(values, 1)
    end
  end

  return setmetatable(ch, { __call = next })
end

return M
