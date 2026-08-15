local async = require "goto.async"

local M = {}

---@generic T
---@class FIFO<T>
---@field clear fun()
---@field empty fun(): boolean
---@field pop fun(): T?
---@field push fun(value: T)

---@generic T
---@return FIFO<T>
M.fifo = function()
  local f = {}

  local values = {}
  local first, last = 1, 0

  f.clear = function()
    values = {}
    first, last = 1, 0
  end

  f.empty = function()
    return first > last
  end

  f.push = function(value)
    last = last + 1
    values[last] = value
  end

  f.pop = function()
    if f.empty() then
      return
    end
    local value = values[first]
    values[first] = nil
    first = first + 1
    if f.empty() then
      f.clear()
    end
    return value
  end

  return f
end

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
  local values = M.fifo()
  local pending ---@type { elapsed: boolean, resolve: fun(elapsed: boolean), scheduled: boolean }?

  local notify = function(elapsed)
    if pending and not pending.scheduled then
      pending.elapsed = elapsed
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
    values.clear()
    notify(false)
  end

  ch.send = function(value)
    assert(value ~= nil, "mpsc: nil message")
    if closed then
      return false
    end
    values.push(value)
    notify(false)
    return true
  end

  ch.wait = function(milliseconds)
    if closed or not values.empty() then
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
    elseif not values.empty() then
      return values.pop()
    end
    local future = await()
    future.await()
    if not closed then
      return values.pop()
    end
  end

  return setmetatable(ch, { __call = next })
end

return M
