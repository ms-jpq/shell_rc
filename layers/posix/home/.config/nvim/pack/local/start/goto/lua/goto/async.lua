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
  local queued = {}
  local resolve ---@type fun(elapsed?: boolean)?

  local ch = {}

  local wake = function(elapsed)
    if resolve then
      local resume = resolve
      resolve = nil
      vim.schedule(function()
        resume(elapsed)
      end)
    end
  end

  ch.close = function()
    if closed then
      return
    end
    closed = true
    queued = {}
    wake(false)
  end

  ch.send = function(value)
    if closed then
      return false
    end
    table.insert(queued, value)
    wake(false)
    return true
  end

  ch.wait = function(milliseconds)
    if closed or #queued > 0 then
      return false
    end
    assert(not resolve, "mpsc: multiple consumers")
    local future = M.future()
    local resume = future.resolve
    resolve = resume
    vim.defer_fn(function()
      if resolve == resume then
        wake(true)
      end
    end, milliseconds)
    return future.await() == true
  end

  local next = function()
    if closed then
      return
    elseif #queued > 0 then
      return table.remove(queued, 1)
    end
    assert(not resolve, "mpsc: multiple consumers")
    local future = M.future()
    resolve = future.resolve
    future.await()
    resolve = nil
    if not closed then
      return table.remove(queued, 1)
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
