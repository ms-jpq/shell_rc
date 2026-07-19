local hsminweb = require "hs.httpserver.hsminweb"

local M = {}

local ROOT = hs.configdir .. "/og/desktop"
local PORT = 42069
local URL = "http://localhost:" .. PORT .. "/"
local MAINTENANCE_INTERVAL = 5

local start_server = function()
  return hsminweb.new(ROOT):bonjour(false):interface("localhost"):port(PORT):allowDirectory(false):start()
end

local new_desktop = function(screen)
  return hs.webview
    .new(screen:fullFrame(), {
      allowsAirPlay = false,
      privateBrowsing = true,
    })
    :behaviorAsLabels({ "stationary", "canJoinAllSpaces" })
    :url(URL .. "?reload=" .. hs.timer.secondsSinceEpoch())
    :transparent(true)
    :sendToBack()
    :show()
end

local maintain_desktops = function()
  local views = _G.desktop_views
  local present = {}

  for _, screen in ipairs(hs.screen.allScreens()) do
    local id = screen:id()
    present[id] = true
    if views[id] then
      views[id]:frame(screen:fullFrame()):show():sendToBack()
    else
      views[id] = new_desktop(screen)
    end
  end

  for id, view in pairs(views) do
    if not present[id] then
      view:delete()
      views[id] = nil
    end
  end
end

local clear_desktops = function()
  for _, view in pairs(_G.desktop_views or {}) do
    view:delete()
  end
  _G.desktop_views = {}
end

M.init = function()
  _G.desktop_server = _G.desktop_server or start_server()

  clear_desktops()
  maintain_desktops()
  if not _G.desktop_maintenance then
    _G.desktop_maintenance = hs.timer.doEvery(MAINTENANCE_INTERVAL, maintain_desktops):start()
  end
end

return M
