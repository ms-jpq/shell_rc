local M = {}

local SIZE = 64
local RADIUS = 48
local ANGLE_DECAY = 0.18
local IMAGE = hs.configdir .. "/togo/desktop/cursor.png"

local clamp = function(lo, value, hi)
  return math.max(lo, math.min(value, hi))
end

local angle_difference = function(from, to)
  return (to - from + math.pi) % (2 * math.pi) - math.pi
end

local new_view = function()
  local image = assert(hs.image.imageFromPath(IMAGE))
  return hs.canvas
    .new({ x = 0, y = 0, w = SIZE, h = SIZE })
    :appendElements({ type = "image", image = image })
    :behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
    :clickActivating(false)
    :level("cursor")
    :show()
end

local new_cursor = function()
  local angle
  local previous
  local target
  local tap
  local view = new_view()

  local direction = function(point, frame)
    local x = (frame.x + frame.w / 2 - point.x) / (frame.w / 2)
    local y = (frame.y + frame.h / 2 - point.y) / (frame.h / 2)
    local now = hs.timer.secondsSinceEpoch()
    local next = math.atan(y, x)

    if not angle then
      angle = next
      target = next
    else
      local elapsed = now - previous
      local decay = math.exp(-elapsed / ANGLE_DECAY)
      target = target + angle_difference(target, next)
      angle = angle + (target - angle) * (1 - decay)
    end
    previous = now
    return { x = math.cos(angle), y = math.sin(angle) }
  end

  local position = function()
    local point = hs.mouse.absolutePosition()
    local frame = assert(hs.mouse.getCurrentScreen()):fullFrame()
    local offset = RADIUS + SIZE / 2
    local vector = direction(point, frame)
    return {
      x = clamp(frame.x, point.x + vector.x * offset - SIZE / 2, frame.x + frame.w - SIZE),
      y = clamp(frame.y, point.y + vector.y * offset - SIZE / 2, frame.y + frame.h - SIZE),
    }
  end

  local move = function()
    view:topLeft(position())
    return false
  end

  local start = function()
    tap = hs.eventtap
      .new({
        hs.eventtap.event.types.mouseMoved,
        hs.eventtap.event.types.leftMouseDragged,
        hs.eventtap.event.types.rightMouseDragged,
        hs.eventtap.event.types.otherMouseDragged,
      }, move)
      :start()
    move()
  end

  local stop = function()
    tap:stop()
    view:delete()
  end

  return { start = start, stop = stop }
end

M.init = function()
  local previous = _G.togo_cursor
  if previous then
    previous.stop()
  end

  local cursor = new_cursor()
  _G.togo_cursor = cursor
  cursor.start()
end

return M
