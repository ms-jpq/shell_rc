local future = function()
  local thread = coroutine.running()
  assert(thread, "future: must be called inside running coroutine")

  local resolved = nil
  local resolve = function(err, result)
    if coroutine.status(thread) == "running" then
      resolved = { err, result }
    else
      local ok, msg = coroutine.resume(thread, err, result)
      if not ok then
        error(msg)
      end
    end
  end

  local await = function()
    if resolved then
      return unpack(resolved)
    end
    return coroutine.yield()
  end

  return resolve, await
end

local wrap = function(fn)
  return function(...)
    local resolve, await = future()
    local argv = { ... }
    table.insert(argv, resolve)

    fn(unpack(argv))
    return await()
  end
end

local thunk = function(fn)
  return function(...)
    local argv = { ... }
    local thread = coroutine.create(function()
      fn(unpack(argv))
    end)

    local ok, ret = coroutine.resume(thread)
    if not ok then
      local tb = debug.traceback(thread, ret)
      error(tb)
    end
  end
end

return {
  future = future,
  wrap = wrap,
  thunk = thunk,
  run = function(fn)
    thunk(fn)()
  end,
  sleep = function(milliseconds)
    local resolve, await = future()
    vim.defer_fn(resolve, milliseconds)
    return await()
  end,
  scheduled = wrap(vim.schedule),
  system = wrap(vim.system),
  api = {
    nvim_buf_call = wrap(vim.api.nvim_buf_call),
  },
}
