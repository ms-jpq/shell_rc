local M = {}

M.future = function()
  local thread = coroutine.running()
  assert(thread, "future: must be called inside running coroutine")

  local f = {}
  local resolved = nil

  f.resolve = function(...)
    if coroutine.status(thread) == "running" then
      resolved = { ... }
    else
      local ok, msg = coroutine.resume(thread, ...)
      if not ok then
        local tb = debug.traceback(thread, msg)
        error(tb, 0)
      end
    end
  end

  f.await = function()
    if resolved then
      return unpack(resolved)
    end
    return coroutine.yield()
  end

  return f
end

M.wrap = function(fn)
  return function(...)
    local f = M.future()
    local argv = { ... }
    table.insert(argv, f.resolve)

    fn(unpack(argv))
    return f.await()
  end
end

local lift = function(fn)
  return function(...)
    local argv = { ... }
    local thread = coroutine.create(function()
      fn(unpack(argv))
    end)

    local ok, ret = coroutine.resume(thread)
    if not ok then
      local tb = debug.traceback(thread, ret)
      error(tb, 0)
    end
  end
end

M.run = function(fn)
  lift(fn)()
end

M.sleep = function(milliseconds)
  local f = M.future()
  vim.defer_fn(f.resolve, milliseconds)
  return f.await()
end

M.scheduled = M.wrap(vim.schedule)
M.system = M.wrap(vim.system)

M.uv = {
  fs_close = M.wrap(vim.uv.fs_close),
  fs_open = M.wrap(vim.uv.fs_open),
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
