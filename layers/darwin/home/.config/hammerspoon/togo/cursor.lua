local screen = require "togo.lib.screen"

local M = {}

local RADIUS, SIZE = 40, 40
local EDGE_PADDING = 8
local ANGLE_DECAY = 0.18
local FRAME_INTERVAL = 1 / 60
local IMAGE_EXTENSIONS = { gif = true, jpeg = true, jpg = true, png = true }

---@class CursorPoint
---@field x number
---@field y number

---@class CursorFrame: CursorPoint
---@field w number
---@field h number

---@class CursorVector: CursorPoint

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

---@param point CursorPoint
---@param frame CursorFrame
---@return number bearing
---@return number radius
local polar = function(point, frame)
  local x = (frame.x + frame.w / 2 - point.x) / (frame.w / 2)
  local y = (frame.y + frame.h / 2 - point.y) / (frame.h / 2)
  local radius = math.min(1, math.sqrt(x * x + y * y))
  ---@diagnostic disable-next-line: redundant-parameter
  return math.atan(y, x), radius
end

local new_direction = function()
  local displayed, target, gain, screen_id = nil, nil, 0, nil
  local time = hs.timer.secondsSinceEpoch()

  ---@param point CursorPoint
  ---@param frame CursorFrame
  ---@param id integer
  local aim = function(point, frame, id)
    local bearing, radius = polar(point, frame)

    gain = smoothstep(radius)
    if screen_id ~= id then
      displayed = bearing
      target = bearing
      screen_id = id
    else
      target = target + angle_difference(target, bearing)
    end
  end

  ---@return CursorVector
  local vector = function()
    local now = hs.timer.secondsSinceEpoch()
    local elapsed = math.min(now - time, FRAME_INTERVAL)
    local decay = math.exp(-elapsed / ANGLE_DECAY)
    local blend = (1 - decay) * gain
    displayed = displayed + (target - displayed) * blend
    time = now
    return { x = math.cos(displayed), y = math.sin(displayed) }
  end

  return { aim = aim, vector = vector }
end

local new_view = function()
  local image = hs.image.imageFromPath(img_src())
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
    :level "cursor"
end

local new_cursor = function()
  local dirty = false
  ---@type CursorPoint
  local point = { x = 0, y = 0 }
  ---@type CursorFrame
  local frame = { x = 0, y = 0, w = 0, h = 0 }
  local screen_watcher, tap, timer = nil, nil, nil
  ---@type TogoScreenSettler?
  local settler = nil
  local view = new_view()
  local direction = new_direction()

  ---@param vector CursorVector
  local position = function(vector)
    local offset = RADIUS + SIZE / 2
    return {
      x = clamp(
        frame.x + EDGE_PADDING,
        point.x + vector.x * offset - SIZE / 2,
        frame.x + frame.w - SIZE - EDGE_PADDING
      ),
      y = clamp(
        frame.y + EDGE_PADDING,
        point.y + vector.y * offset - SIZE / 2,
        frame.y + frame.h - SIZE - EDGE_PADDING
      ),
    }
  end

  local cancel = function()
    dirty = false
    if timer then
      timer:stop()
      timer = nil
    end
  end

  local render = function()
    if not dirty then
      return cancel()
    end
    dirty = false
    view:show()
    view:topLeft(position(direction.vector()))
  end

  local hide = function()
    cancel()
    view:hide()
    return false
  end

  local move = function()
    local current = hs.mouse.getCurrentScreen()
    if not current then
      return hide()
    end

    point = hs.mouse.absolutePosition()
    frame = current:fullFrame()
    ---@cast point CursorPoint
    ---@cast frame CursorFrame
    direction.aim(point, frame, current:id())
    dirty = true
    if timer then
      return false
    end
    render()
    timer = hs.timer.doEvery(FRAME_INTERVAL, render)
    return false
  end

  local react = function(event)
    if event:getType() == hs.eventtap.event.types.keyDown then
      return hide()
    end
    return move()
  end

  local sample = function()
    local current = hs.mouse.getCurrentScreen()
    if not current then
      return
    end

    local current_frame = current:fullFrame()
    return string.format(
      "%d:%f:%f:%f:%f",
      current:id(),
      current_frame.x,
      current_frame.y,
      current_frame.w,
      current_frame.h
    )
  end

  local settle = function()
    hide()
    assert(settler).restart()
  end

  local start = function()
    tap = hs.eventtap
      .new({
        hs.eventtap.event.types.keyDown,
        hs.eventtap.event.types.leftMouseDown,
        hs.eventtap.event.types.leftMouseDragged,
        hs.eventtap.event.types.mouseMoved,
        hs.eventtap.event.types.otherMouseDown,
        hs.eventtap.event.types.otherMouseDragged,
        hs.eventtap.event.types.rightMouseDown,
        hs.eventtap.event.types.rightMouseDragged,
      }, react)
      :start()
    settler = screen.new_settler(sample, move)
    screen_watcher = hs.screen.watcher
      .new(function()
        settle()
      end)
      :start()
    move()
  end

  local stop = function()
    if tap then
      tap:stop()
    end
    if screen_watcher then
      screen_watcher:stop()
    end
    if settler then
      settler.stop()
    end
    cancel()
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
