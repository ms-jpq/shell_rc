#!/usr/bin/env -S -- hs

local argv = _cli and _cli.args or {}
local title, body, sound, id = table.unpack(argv, 2, 5)

local function present(s)
  return s and #s > 0 and s or nil
end

local function on_click()
  hs.application.launchOrFocus "kitty"
end

local notify = hs.notify.new(on_click, {
  title = present(title),
  informativeText = present(body),
  soundName = present(sound),
  withdrawAfter = 0,
})

do
  _G.__notifications = _G.__notifications or {}
  local prev = _G.__notifications[id]
  if prev then
    prev:withdraw()
  end
  if present(id) then
    _G.__notifications[id] = notify
  end
end

---@diagnostic disable-next-line
notify:send()
