#!/usr/bin/env -S -- hs

local KITTEN = "/Applications/kitty.app/Contents/MacOS/kitten"

local app = hs.application.find "kitty"
local win = app and (app:allWindows() or {})[1]
if not win then
  io.stderr:write "no kitty window\n"
  os.exit(1)
end

local out, ok = hs.execute(KITTEN .. " @ ls", false)
if not ok then
  io.stderr:write "kitten @ ls failed\n"
  os.exit(1)
end

local data = hs.json.decode(out or "") or {}
local w = (((data[1] or {}).tabs or {})[1] or {}).windows
w = w and w[1]
if not w or not w.columns or not w.lines then
  io.stderr:write "no window data\n"
  os.exit(1)
end

local frame = win:frame()
local cell_w = frame.w / w.columns
local cell_h = frame.h / w.lines

print(string.format("frame:    %dx%d", frame.w, frame.h))
print(string.format("grid:     %dx%d", w.columns, w.lines))
print(string.format("cell:     %.3f x %.3f", cell_w, cell_h))
print(string.format("ratios:   w=%.3f  h=%.3f  (divide by FONT_SIZE for kitty.lua constants)", cell_w, cell_h))
