local lib = require "og.lib"

local M = {}

local NVIM_SOCK = lib.HOME .. "/.cache/nvim/quic.sock"

local quake = function()
  lib.run { lib.KITTEN, "quick-access-terminal" }
end

local tmpfile = function(text)
  local tmp = string.format("%sedit-%d.md", os.getenv "TMPDIR" or "/tmp/", os.time())
  local sentinel = tmp .. ".done"

  local fw = io.open(tmp, "w")
  if fw then
    fw:write(text)
    fw:close()
  end

  return tmp,
    sentinel,
    function()
      os.remove(sentinel)
      local fr = io.open(tmp, "r")
      local read = fr and fr:read "*a" or ""
      if fr then
        fr:close()
      end
      os.remove(tmp)
      return (string.gsub(read, "%s+$", ""))
    end
end

local function slurp()
  local prev = hs.pasteboard.getContents()
  hs.pasteboard.setContents ""
  local before = hs.pasteboard.changeCount()
  hs.eventtap.keyStroke({ "cmd" }, "a", 0)
  hs.eventtap.keyStroke({ "cmd" }, "c", 0)
  for _ = 1, 20 do
    if hs.pasteboard.changeCount() ~= before then
      break
    end
    hs.timer.usleep(5 * 1000)
  end
  local text = hs.pasteboard.getContents() or ""
  hs.pasteboard.setContents(prev or "")
  return text
end

local function spit(text)
  local prev = hs.pasteboard.getContents()
  hs.pasteboard.setContents(text)
  hs.eventtap.keyStroke({ "cmd" }, "v", 0)
  hs.timer.doAfter(0.3, function()
    hs.pasteboard.setContents(prev or "")
  end)
end

local function edit_in_kitty()
  local app = hs.application.frontmostApplication()
  if not app or app:name() == "kitty-quick-access" then
    return
  end

  local pre_text = slurp()
  local tmp, sentinel, read = tmpfile(pre_text)
  local done = function()
    local post_text = read()
    app:activate()
    spit(post_text)
  end

  lib.wait_for(NVIM_SOCK, function()
    lib.run { lib.KITTEN, "quick-access-terminal", "--instance-group=edit" }
    lib.run { "/opt/homebrew/bin/nvim", "--server", NVIM_SOCK, "--remote", tmp }
    lib.wait_for(sentinel, done)
  end)
end

M.init = function()
  _G.quakeHotkey = hs.hotkey.bind({ "cmd", "shift" }, "u", quake)
  _G.editHotkey = hs.hotkey.bind({ "cmd", "shift" }, "e", edit_in_kitty)
end

return M
