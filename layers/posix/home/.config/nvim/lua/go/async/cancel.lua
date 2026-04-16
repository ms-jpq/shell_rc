return function(parent)
  local watchers = {}
  local token = { cancelled = false }

  token.cancel = function()
    if token.cancelled then
      return
    end
    token.cancelled = true
    for _, watcher in pairs(watchers) do
      if type(watcher) == "function" then
        watcher()
      else
        watcher.cancel()
      end
    end
  end

  token.watch = function(watcher)
    table.insert(watchers, watcher)
  end

  if parent then
    parent.watch(token)
    if parent.cancelled then
      token.cancel()
    end
  end

  return token
end
