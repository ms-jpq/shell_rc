local M = {}

M.future = function()
  local thread = coroutine.running()
  assert(thread, "future: must be called inside running coroutine")

  local fut = {}
  local resolved = nil

  fut.resolve = function(...)
    if coroutine.status(thread) == "running" then
      resolved = { ... }
    else
      local ok, err = coroutine.resume(thread, ...)
      if not ok then
        error(debug.traceback(thread, err), 0)
      end
    end
  end

  fut.await = function()
    if resolved then
      return unpack(resolved)
    end
    return coroutine.yield()
  end

  return fut
end

M.wrap = function(fn)
  return function(...)
    local fut = M.future()
    local argv = { ... }
    table.insert(argv, fut.resolve)
    fn(unpack(argv))
    return fut.await()
  end
end

local lift = function(fn)
  return function(...)
    local argv = { ... }
    local thread = coroutine.create(function()
      fn(unpack(argv))
    end)

    local ok, err = coroutine.resume(thread)
    if not ok then
      error(debug.traceback(thread, err), 0)
    end
  end
end

M.run = function(fn)
  lift(fn)()
end

M.sleep = function(milliseconds)
  local fut = M.future()
  vim.defer_fn(fut.resolve, milliseconds)
  return fut.await()
end

---@generic T
---@class AsyncMpsc<T>
---@field close fun()
---@field send fun(value: T): boolean
---@field wait fun(milliseconds: integer): boolean
---@operator call: fun(...: any): T?

---@generic T
---@return AsyncMpsc<T>
M.mpsc = function()
  local closed = false
  local queue = {}
  local pending ---@type { elapsed: boolean, resolve: fun(elapsed: boolean), scheduled: boolean }?

  local ch = {}

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
    local future = M.future()
    pending = { elapsed = false, resolve = future.resolve, scheduled = false }
    return future
  end

  ch.close = function()
    if closed then
      return
    end
    closed = true
    queue = {}
    notify(false)
  end

  ch.send = function(value)
    assert(value ~= nil, "mpsc: nil message")
    if closed then
      return false
    end
    table.insert(queue, value)
    notify(false)
    return true
  end

  ch.wait = function(milliseconds)
    if closed or #queue > 0 then
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
    elseif #queue > 0 then
      return table.remove(queue, 1)
    end
    local future = await()
    future.await()
    if not closed then
      return table.remove(queue, 1)
    end
  end

  return setmetatable(ch, { __call = next })
end

---@param bytecode string
local transfer = function(bytecode, ...)
  return assert(load(bytecode))(...)
end

M.work = function(fn, ...)
  local fut = M.future()
  local work = vim.uv.new_work(transfer, vim.schedule_wrap(fut.resolve))
  work:queue(string.dump(fn), ...)
  return fut.await()
end

M.scheduled = M.wrap(vim.schedule)
M.system = M.wrap(vim.system)

M.uv = {
  fs_close = M.wrap(vim.uv.fs_close),
  fs_open = M.wrap(vim.uv.fs_open),
  fs_realpath = M.wrap(vim.uv.fs_realpath),
  fs_stat = M.wrap(vim.uv.fs_stat),
  fs_unlink = M.wrap(vim.uv.fs_unlink),
}

M.fn = {
  jobstart = M.wrap(function(cmd, opts, on_exit)
    opts = opts or {}
    opts.on_exit = on_exit
    vim.fn.jobstart(cmd, opts)
  end),
}

M.ui = {
  select = M.wrap(vim.ui.select),
}

return setmetatable(M, {
  __call = function(_, fn)
    return lift(fn)
  end,
})
