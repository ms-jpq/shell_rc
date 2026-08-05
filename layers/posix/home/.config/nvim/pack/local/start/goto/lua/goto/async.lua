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
