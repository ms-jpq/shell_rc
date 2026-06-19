#!/usr/bin/env -S -- hs

local argv = _cli and _cli.args or {}
local title, subtitle, body, sound = table.unpack(argv, 2, 5)

local function present(s)
  return s and #s > 0 and s or nil
end

local notify = hs.notify.new {
  title = present(title),
  subTitle = present(subtitle),
  informativeText = present(body),
  soundName = present(sound),
} --[[@as hs.notify]]

notify:send()
