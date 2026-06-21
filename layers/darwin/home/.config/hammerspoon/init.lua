require "hs.ipc"

local st = function()
  return false
end

local function run(arg0, args)
  return hs.task.new(arg0, nil, st, args):start()
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

  local tmpfile = function(text)
    local tmp = string.format("%sedit-%d.md", os.getenv "TMPDIR" or "/tmp/", os.time())

    local fw = io.open(tmp, "w")
    if fw then
      fw:write(text)
      fw:close()
    end

    return tmp,
      function()
        local fr = io.open(tmp, "r")
        local read = fr and fr:read "*a" or ""
        if fr then
          fr:close()
        end
        os.remove(tmp)
        return read
      end
  end

  local function slurp()
    local prev = hs.pasteboard.getContents()
    hs.pasteboard.setContents ""
    hs.eventtap.keyStroke({ "cmd" }, "a", 0)
    hs.eventtap.keyStroke({ "cmd" }, "c", 0)
    hs.timer.usleep(150000)
    local text = hs.pasteboard.getContents() or ""
    hs.pasteboard.setContents(prev or "")
    return text
  end

  local function spit(text)
    local prev = hs.pasteboard.getContents()
    hs.pasteboard.setContents(text)
    hs.eventtap.keyStroke({ "cmd" }, "v", 0)
    hs.timer.doAfter(0.3, function()
      hs.pasteboard.setContents(prev or "")
    end)
  end

  local function edit_in_kitty()
    local app = hs.application.frontmostApplication()
    if not app then
      return
    end

    local pre_text = slurp()
    local tmp, read = tmpfile(pre_text)

    hs.task
      .new(
        KITTEN,
        function()
          local post_text = read()
          app:activate()
          hs.timer.doAfter(0.09, function()
            spit(post_text)
          end)
        end,
        st,
        {
          "quick-access-terminal",
          "--instance-group=edit",
          "--",
          "/opt/homebrew/bin/zsh",
          "-ic",
          [[nvim -- "$1"]],
          "-",
          tmp,
        }
      )
      :start()
  end

  _G.editHotkey = hs.hotkey.bind({ "cmd", "shift" }, "e", edit_in_kitty)
end
