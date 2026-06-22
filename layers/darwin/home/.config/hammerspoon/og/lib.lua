local M = {}

M.HOME = os.getenv "HOME" or ""

M.KITTEN = "/opt/homebrew/bin/kitten"

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
  hs.timer.doAfter(0.01, function()
    M.wait_for(path, cb)
  end)
end

return M
