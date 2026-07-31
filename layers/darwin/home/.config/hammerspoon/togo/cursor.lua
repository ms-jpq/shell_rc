local M = {}

local RADIUS, SIZE = 40, 40
local ANGLE_DECAY = 0.18

local IMAGE_EXTENSIONS = { gif = true, jpeg = true, jpg = true, png = true }

local img_src = function()
  local desktop = hs.configdir .. "/togo/desktop/"
  local paths = {}
  for name in hs.fs.dir(desktop) do
    local extension = string.match(name, "%.([^.]+)$")
    if extension and IMAGE_EXTENSIONS[string.lower(extension)] then
      table.insert(paths, desktop .. name)
    end
  end
  return paths[math.random(#paths)]
end

local clamp = function(lo, value, hi)
  return math.max(lo, math.min(value, hi))
end

local angle_difference = function(from, to)
  return (to - from + math.pi) % (2 * math.pi) - math.pi
end

local smoothstep = function(value)
  return value * value * (3 - 2 * value)
end

local polar = function(point, frame)
  local x = (frame.x + frame.w / 2 - point.x) / (frame.w / 2)
  local y = (frame.y + frame.h / 2 - point.y) / (frame.h / 2)
  local radius = math.min(1, math.sqrt(x * x + y * y))
  ---@diagnostic disable-next-line: redundant-parameter
  return math.atan(y, x), radius
end

local new_direction = function()
  local displayed, target = nil, nil
  local time = hs.timer.secondsSinceEpoch()

  return function(point, frame)
    local bearing, radius = polar(point, frame)
    local gain = smoothstep(radius)
    local now = hs.timer.secondsSinceEpoch()

    if not displayed then
      displayed = bearing
      target = bearing
    else
      local elapsed = now - time
      local decay = math.exp(-elapsed / ANGLE_DECAY)
      local blend = (1 - decay) * gain
      target = target + angle_difference(target, bearing)
      displayed = displayed + (target - displayed) * blend
    end
    time = now
    return { x = math.cos(displayed), y = math.sin(displayed) }
  end
end

local new_view = function()
  local src = img_src()
  local image = hs.image.imageFromPath(src)
  return hs
    .canvas
    .new({ x = 0, y = 0, w = SIZE, h = SIZE })
    ---@diagnostic disable-next-line: undefined-field
    :appendElements({
      type = "image",
      image = image,
      imageAnimates = true,
    })
    :behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
    :clickActivating(false)
    :level("cursor")
    :show()
end

local new_cursor = function()
  local tap = nil
  local view = new_view()
  local direction = new_direction()

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
