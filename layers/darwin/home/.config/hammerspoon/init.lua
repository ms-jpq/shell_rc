require "hs.ipc"

do
  local function main_screen()
    for _, screen in ipairs(hs.screen.allScreens()) do
      if not string.find(string.lower(screen:name() or ""), "built%-in") then
        if screen:id() ~= hs.screen.primaryScreen():id() then
          screen:setPrimary()
        end
        return
      end
    end
  end

  _G.screenWatcher = hs.screen.watcher.new(main_screen):start()
  main_screen()
end
