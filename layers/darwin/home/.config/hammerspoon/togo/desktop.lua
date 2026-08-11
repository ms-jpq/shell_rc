local hsminweb = require "hs.httpserver.hsminweb"
local screen = require "togo.lib.screen"

local M = {}

local ROOT = hs.configdir .. "/togo/desktop"
local PORT = 42069
local URL = "http://localhost:" .. PORT .. "/"
local MAINTENANCE_INTERVAL = 6
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
  local screen_watcher, timer = nil, nil
  ---@type TogoScreenSettler?
  local settler = nil
  local views = {}

  local snapshot = function(screens)
    if #screens == 0 then
      return nil
    end

    local frames = {}
    for _, screen in ipairs(screens) do
      local frame = screen:fullFrame()
      table.insert(frames, string.format("%d:%f:%f:%f:%f", screen:id(), frame.x, frame.y, frame.w, frame.h))
    end
    table.sort(frames)
    return table.concat(frames, "|")
  end

  local maintain = function(screens)
    local present = {}

    ---@diagnostic disable-next-line: param-type-mismatch
    for _, screen in ipairs(screens or hs.screen.allScreens()) do
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

  local sample = function()
    local screens = hs.screen.allScreens()
    maintain(screens)
    return snapshot(screens)
  end

  local settle = function()
    assert(settler).restart()
  end

  local start = function()
    maintain()
    timer = hs.timer.doEvery(MAINTENANCE_INTERVAL, maintain):start()
    settler = screen.new_settler(sample)
    screen_watcher = hs.screen.watcher
      .new(function()
        settle()
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
    if settler then
      settler.stop()
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
