#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

read -r -d '' -- LUA <<- 'LUA' || true
local notifs = hs.notify.deliveredNotifications() or {}

table.sort(notifs, function(a, b)
  return (a:actualDeliveryDate() or 0) < (b:actualDeliveryDate() or 0)
end)

local out = {}
for _, n in ipairs(notifs) do
  local t = n:actualDeliveryDate()
  local title = n:title() or "(no title)"
  local time = t and os.date("%Y-%m-%d %H:%M", t) or ""
  local body = n:informativeText() or ""
  table.insert(out, ("# >>> %s\n\n*%s*\n\n%s"):format(title, time, body))
end

print(table.concat(out, "\n\n---\n\n"))

hs.notify.withdrawAll()
LUA

TMP="$(mktemp -t hsl.XXXXXX.md)"
hs -c "$LUA" > "$TMP"

tmux-edit -c '/\V# >>>' -- "$TMP"
