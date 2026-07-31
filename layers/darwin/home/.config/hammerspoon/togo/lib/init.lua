local M = {}

M.HOME = os.getenv "HOME" or ""

M.lock = function(fn, busy)
  local active = false

  return function(...)
    if active then
      if busy then
        busy(...)
      end
      return
    end

    active = true

    local unlock = function()
      active = false
    end

    local ok, err = pcall(fn, unlock, ...)
    if not ok then
      unlock()
      error(err)
    end
  end
end

do
  local st = function()
    return false
  end

  M.run = function(argv, done)
    local arg0 = table.unpack(argv)
    local args = { table.unpack(argv, 2) }
    return hs.task.new(arg0, done, st, args):start()
  end
end

M.wait_for = function(path, cb)
  if hs.fs.attributes(path) then
    cb()
    return
  end
  local dir = string.match(path, "^(.*)/[^/]+$") or "."
  ---@type any
  local watcher = nil
  watcher = hs.pathwatcher
    .new(dir, function()
      if hs.fs.attributes(path) then
        watcher:stop()
        cb()
      end
    end)
    :start()
end

return M
