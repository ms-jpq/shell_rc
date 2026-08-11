local hsminweb = require "hs.httpserver.hsminweb"

local M = {}

local ROOT = hs.configdir .. "/togo/desktop"
local PORT = 42069
local URL = "http://localhost:" .. PORT .. "/"
local MAINTENANCE_INTERVAL = 6
local SCREEN_SETTLE_DELAY = 0.1

local start_server = function()
  return hsminweb.new(ROOT):bonjour(false):interface("localhost"):port(PORT):allowDirectory(false):start()
end

local new_view = function(screen)
  return hs
    .webview
    .new(screen:fullFrame(), {
      allowsAirPlay = false,
      javaScriptCanOpenWindowsAutomatically = false,
      privateBrowsing = true,
    })
    ---@diagnostic disable-next-line: undefined-field
    :behaviorAsLabels({ "stationary", "canJoinAllSpaces" })
    :url(URL .. "?reload=" .. hs.timer.secondsSinceEpoch())
    :transparent(true)
    :show()
    :sendToBack()
end

local new_desktop = function()
  local server = start_server()
  local screen_watcher, settle, timer = nil, nil, nil
  local views = {}

  local maintain = function()
    local present = {}

    ---@diagnostic disable-next-line: param-type-mismatch
    for _, screen in ipairs(hs.screen.allScreens()) do
      local id = screen:id()
      present[id] = true
      if views[id] then
        views[id]:frame(screen:fullFrame()):show():sendToBack()
      else
        views[id] = new_view(screen)
      end
    end

    for id, view in pairs(views) do
      if not present[id] then
        view:delete()
        views[id] = nil
      end
    end
  end

  local start = function()
    maintain()
    timer = hs.timer.doEvery(MAINTENANCE_INTERVAL, maintain):start()
    screen_watcher = hs.screen.watcher
      .new(function()
        maintain()
        if settle then
          settle:stop()
        end
        settle = hs.timer.doAfter(SCREEN_SETTLE_DELAY, maintain)
      end)
      :start()
  end

  local stop = function()
    if timer then
      timer:stop()
    end
    if screen_watcher then
      screen_watcher:stop()
    end
    if settle then
      settle:stop()
    end
    for _, view in pairs(views) do
      view:delete()
    end
    server:stop()
  end

  return { start = start, stop = stop }
end

M.init = function()
  local previous = _G.togo_desktop
  if previous then
    previous.stop()
  else
    if _G.desktop_maintenance then
      _G.desktop_maintenance:stop()
    end
    if _G.desktop_views then
      for _, view in pairs(_G.desktop_views) do
        view:delete()
      end
    end
    if _G.desktop_server then
      _G.desktop_server:stop()
    end
  end

  local desktop = new_desktop()
  _G.togo_desktop = desktop
  _G.desktop_maintenance, _G.desktop_server, _G.desktop_views = nil, nil, nil
  desktop.start()
end

return M
