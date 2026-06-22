#!/usr/bin/env -S -- hs

local argv = _cli and _cli.args or {}
local title, body, sound, id = table.unpack(argv, 2, 5)

local function present(s)
  return s and #s > 0 and s or nil
end

local tag = present(id) or hs.host.uuid()

local function on_click()
  hs.application.launchOrFocus "kitty"
end

do
  for _, n in pairs(hs.notify.deliveredNotifications() or {}) do
    if n:getFunctionTag() == tag then
      n:withdraw()
    end
  end

  hs.notify.register(tag, on_click)
end

local notify = hs.notify.new(tag, {
  title = present(title),
  informativeText = present(body),
  soundName = present(sound),
  withdrawAfter = 0,
})

if present(title) or present(body) then
  ---@diagnostic disable-next-line
  notify:send()
end
