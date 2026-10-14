local M = {}

---@class TogoLifecycle
---@field start fun()
---@field stop fun()

---@param create fun(): TogoLifecycle
---@return TogoLifecycle
M.new = function(create)
  local instance, watcher = nil, nil
  local system_asleep, screens_asleep = false, false

  local suspend = function()
    if instance then
      instance.stop()
      instance = nil
    end
  end

  local resume = function()
    if not instance and not system_asleep and not screens_asleep then
      instance = create()
      instance.start()
    end
  end

  local changed = function(event)
    local events = hs.caffeinate.watcher
    if event == events.systemWillSleep then
      system_asleep = true
    elseif event == events.systemDidWake then
      system_asleep = false
    elseif event == events.screensDidSleep then
      screens_asleep = true
    elseif event == events.screensDidWake then
      screens_asleep = false
    else
      return
    end

    if system_asleep or screens_asleep then
      suspend()
    else
      resume()
    end
  end

  local start = function()
    if not watcher then
      system_asleep, screens_asleep = false, false
      watcher = hs.caffeinate.watcher.new(changed):start()
      resume()
    end
  end

  local stop = function()
    if watcher then
      watcher:stop()
      watcher = nil
    end
    suspend()
  end

  return { start = start, stop = stop }
end

return M
