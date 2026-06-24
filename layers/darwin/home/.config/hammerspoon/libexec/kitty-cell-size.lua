#!/usr/bin/env -S -- hs

local KITTEN = "/Applications/kitty.app/Contents/MacOS/kitten"

local app = hs.application.find "kitty"
local win = app and (app:allWindows() or {})[1]
if not win then
  io.stderr:write "no kitty window\n"
  os.exit(1)
end

local socket_path = (function()
  for _, dir in ipairs { hs.fs.temporaryDirectory(), "/tmp" } do
    if hs.fs.attributes(dir, "mode") == "directory" then
      dir = (string.gsub(dir, "/$", "")) .. "/"
      for name in hs.fs.dir(dir) do
        if string.match(name, "^kitty%..*%.sock$") then
          return dir .. name
        end
      end
    end
  end
end)()

local out = (function()
  local to_sock = socket_path and " --to unix:" .. socket_path .. " " or ""
  local cmd = KITTEN .. " @ " .. to_sock .. " ls"
  print(cmd)
  local result, ok = hs.execute(cmd, false)
  if not ok then
    io.stderr:write("kitten @ ls failed:\n" .. (result or "") .. "\n")
    os.exit(1)
  end
  return result
end)()

local data = hs.json.decode(out or "")
if not data then
  io.stderr:write("could not decode JSON from kitten @ ls. raw output:\n" .. (out or "") .. "\n")
  os.exit(1)
end

local os_win = table.unpack(data or {})
local tab = os_win and table.unpack(os_win.tabs or {})
local w = tab and table.unpack(tab.windows or {})
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
