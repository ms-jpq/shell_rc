require "hs.ipc"

local function run(arg0, args)
  return hs.task
    .new(arg0, nil, function()
      return false
    end, args)
    :start()
end

do
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
        run(VPN, { "--quit" })
        hs.alert.show("🔓 VPN off — " .. ssid)
      elseif ssid then
        run(VPN, { "--minimize" })
        hs.alert.show("🔒 VPN on — " .. ssid)
      else
        hs.alert.show "🔒 Wifi off"
      end
    end)
  end

  _G.wifiWatcher = hs.wifi.watcher.new(on_wifi):start()
end

do
  local function main_screen()
    local pid = hs.screen.primaryScreen():id()
    for _, screen in ipairs(hs.screen.allScreens() or {}) do
      local name = string.lower(screen:name() or "")
      if not string.find(name, "built%-in") then
        if screen:id() ~= pid then
          screen:setPrimary()
        end
        return
      end
    end
  end

  _G.screenWatcher = hs.screen.watcher.new(main_screen):start()
  main_screen()
end

do
  local KITTEN = "/opt/homebrew/bin/kitten"

  local slurp = function()
    return ""
  end
  local spit = function(text) end

  local function edit_in_kitty()
    local pre_text = slurp()
    local tmp = ""
    run(KITTEN, { "quick-access-terminal", "--", "nvim", "--", tmp }):waitUntilExit()
    local post_text = ""
    spit(post_text)
  end

  _G.editHotkey = hs.hotkey.bind({ "cmd", "shift" }, "e", edit_in_kitty)
end
