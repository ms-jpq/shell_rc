require "hs.ipc"

local HOME = os.getenv "HOME" or ""

local st = function()
  return false
end

local function run(argv, done)
  local arg0 = table.remove(argv, 1)
  return hs.task.new(arg0, done, st, argv):start()
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
        run({ VPN, "--quit" }, function()
          hs.alert.show("🔓 VPN off — " .. ssid)
        end)
      elseif ssid then
        hs.alert.show("🔒 VPN on — " .. ssid, function()
          run { VPN, "--minimize" }
        end)
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
    local sentinel = tmp .. ".done"

    local fw = io.open(tmp, "w")
    if fw then
      fw:write(text)
      fw:close()
    end

    return tmp,
      sentinel,
      function()
        os.remove(sentinel)
        local fr = io.open(tmp, "r")
        local read = fr and fr:read "*a" or ""
        if fr then
          fr:close()
        end
        os.remove(tmp)
        return read
      end
  end

  local function wait_for(path, cb)
    if hs.fs.attributes(path) then
      cb()
      return
    end
    hs.timer.doAfter(0.01, function()
      wait_for(path, cb)
    end)
  end

  local function slurp()
    local prev = hs.pasteboard.getContents()
    hs.pasteboard.setContents ""
    local before = hs.pasteboard.changeCount()
    hs.eventtap.keyStroke({ "cmd" }, "a", 0)
    hs.eventtap.keyStroke({ "cmd" }, "c", 0)
    for _ = 1, 20 do
      if hs.pasteboard.changeCount() ~= before then
        break
      end
      hs.timer.usleep(5 * 1000)
    end
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

  local NVIM_SOCK = HOME .. "/.cache/nvim/quic.sock"

  local function edit_in_kitty()
    local app = hs.application.frontmostApplication()
    if not app then
      return
    end

    local pre_text = slurp()
    local tmp, sentinel, read = tmpfile(pre_text)
    local done = function()
      local post_text = read()
      app:activate()
      spit(post_text)
    end

    wait_for(NVIM_SOCK, function()
      run { KITTEN, "quick-access-terminal", "--instance-group=edit" }
      run { "/opt/homebrew/bin/nvim", "--server", NVIM_SOCK, "--remote", tmp }
      wait_for(sentinel, done)
    end)
  end

  _G.editHotkey = hs.hotkey.bind({ "cmd", "shift" }, "e", edit_in_kitty)
end
