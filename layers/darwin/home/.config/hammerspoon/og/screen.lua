local M = {}

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

M.init = function()
  _G.screenWatcher = hs.screen.watcher.new(main_screen):start()
  main_screen()
end

return M
