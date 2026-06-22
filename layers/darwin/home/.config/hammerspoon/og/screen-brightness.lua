local M = {}

local prev_state = nil
local levels = {}

local function tick()
  local state = hs.battery.powerSource()

  if state ~= prev_state and levels[state] then
    hs.brightness.set(levels[state])
  end

  levels[state] = hs.brightness.get()
  prev_state = state
end

M.init = function()
  _G.brightnessTimer = hs.timer.doEvery(1, tick):start()
end

return M
