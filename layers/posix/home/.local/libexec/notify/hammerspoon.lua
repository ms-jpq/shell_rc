#!/usr/bin/env -S -- hs

local argv = _cli and _cli.args or {}
local title, body, sound = table.unpack(argv, 2, 4)

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

---@diagnostic disable-next-line
notify:send()
