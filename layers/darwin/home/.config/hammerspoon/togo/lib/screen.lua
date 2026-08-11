local M = {}

local SAMPLE_INTERVAL = 0.1

---@class TogoScreenSettler
---@field restart fun()
---@field stop fun()

---@param sample fun(): string?
---@param settled? fun()
---@return TogoScreenSettler
M.new_settler = function(sample, settled)
  local previous, timer = nil, nil

  local stop = function()
    if timer then
      timer:stop()
      timer = nil
    end
  end

  local tick = function()
    local current = sample()
    if not current or current ~= previous then
      previous = current
      return
    end
    stop()
    if settled then
      settled()
    end
  end

  local restart = function()
    stop()
    previous = nil
    tick()
    timer = hs.timer.doEvery(SAMPLE_INTERVAL, tick)
  end

  return { restart = restart, stop = stop }
end

return M
