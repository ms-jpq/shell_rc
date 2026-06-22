local lib = require "og.lib"

local M = {}

local VPN = "/Applications/OpenVPN Connect/OpenVPN Connect.app/Contents/MacOS/OpenVPN Connect"
local INTERNAL = {
  ["home1"] = true,
  ["home2"] = true,
}

local pending = nil
local function on_wifi(_, event)
  if event ~= "SSIDChange" then
    return
  end

  if pending then
    pending:stop()
  end
  pending = hs.timer.doAfter(2, function()
    local ssid = hs.wifi.currentNetwork()
    if INTERNAL[ssid] then
      lib.run({ VPN, "--quit" }, function()
        hs.alert.show("💤 VPN — " .. ssid)
      end)
    elseif ssid then
      hs.alert.show("☕️ VPN — " .. ssid, function()
        lib.run { VPN, "--minimize" }
      end)
    else
      hs.alert.show "🛫 Wifi"
    end
  end)
end

M.init = function()
  _G.wifiWatcher = hs.wifi.watcher.new(on_wifi):start()
end

return M
