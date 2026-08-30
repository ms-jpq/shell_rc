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
  local waiting ---@type fun()?
  local scheduled = false

  local finish = function(waiter)
    if waiting ~= waiter then
      return
    end
    waiting = nil
    scheduled = false
    waiter()
  end

  local notify = function()
    if not waiting or scheduled then
      return
    end
    local waiter = waiting
    scheduled = true
    vim.schedule(function()
      finish(waiter)
    end)
  end

  local await = function()
    assert(not waiting, "mpsc: consumer already waiting")
    local future = async.future()
    waiting = future.resolve
    return future
  end

  local ch = {}

  ch.close = function()
    if closed then
      return
    end
    closed = true
    values.clear()
    if waiting then
      finish(waiting)
    end
  end

  ch.send = function(value)
    assert(value ~= nil, "mpsc: nil message")
    if closed then
      return false
    end
    values.push(value)
    notify()
    return true
  end

  ch.wait = function(milliseconds)
    if closed or not values.empty() then
      return false
    end
    local future = await()
    local waiter = waiting
    local timed_out = false
    local timer = vim.defer_fn(function()
      if waiting == waiter then
        timed_out = true
        notify()
      end
    end, milliseconds)
    future.await()
    if not timer:is_closing() then
      timer:close()
    end
    return not closed and timed_out and values.empty()
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
