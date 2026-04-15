local wrap = function(fn)
  return function(...)
    local thread = coroutine.running()
    assert(thread, "wrap: must be called inside running coroutine")

    local resolved = nil
    local argv = { ... }
    table.insert(argv, function(...)
      if coroutine.status(thread) == "running" then
        resolved = { ... }
      else
        local ok, err = coroutine.resume(thread, ...)
        if not ok then
          error(err)
        end
      end
    end)
    fn(unpack(argv))

    if resolved then
      return unpack(resolved)
    end
    return coroutine.yield()
  end
end

return {
  wrap = wrap,
  run = function(fn)
    local thread = coroutine.create(fn)

    local ok, ret = coroutine.resume(thread)
    if not ok then
      local tb = debug.traceback(thread, ret)
      error(tb)
    end
  end,
}
