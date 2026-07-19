local M = {}

local prev_state = nil
local levels = {}

local tick = function()
  local state = hs.battery.powerSource()

  if state ~= prev_state and levels[state] then
    hs.brightness.set(levels[state])
  end

  levels[state] = hs.brightness.get()
  prev_state = state
end

M.init = function()
  _G.brightness_timer = hs.timer.doEvery(1, tick):start()
end

return M
