local M = {}

M.HOME = os.getenv "HOME" or ""

local st = function()
  return false
end

M.run = function(argv, done)
  local arg0 = table.remove(argv, 1)
  return hs.task.new(arg0, done, st, argv):start()
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
