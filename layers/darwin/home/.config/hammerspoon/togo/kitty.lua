local clipboard = require "togo.lib.clipboard"
local lib = require "togo.lib"

local M = {}

local KITTEN = "/Applications/kitty.app/Contents/MacOS/kitten"
local NVIM_SOCK = lib.HOME .. "/.cache/nvim/quic.sock"

local FRACTION = 0.9
local FONT_SIZE = 14
local CELL_W = FONT_SIZE * 0.645
local CELL_H = FONT_SIZE * 1.221

local cat = function()
  local frame = hs.screen.mainScreen():frame()
  local cols = math.floor(frame.w * FRACTION / CELL_W)
  local rows = math.floor(frame.h * FRACTION / CELL_H)
  return {
    KITTEN,
    "quick-access-terminal",
    "--override=columns=" .. cols,
    "--override=lines=" .. rows,
  }
end

local quake = function()
  lib.run(cat())
end

local tmpfile = function(text)
  local tmp = string.format("%sedit-%d-%06d.md", hs.fs.temporaryDirectory(), os.time(), math.random(999999))
  local sentinel = tmp .. ".done"

  local fw = io.open(tmp, "w")
  if fw then
    fw:write(text)
    fw:close()
  end

  return tmp,
    sentinel,
    function(verbatim)
      os.remove(sentinel)
      local fr = io.open(tmp, "r")
      local read = fr and fr:read "*a" or ""
      if fr then
        fr:close()
      end
      os.remove(tmp)
      return verbatim and read or string.gsub(read, "%s+$", "")
    end
end

local show_edit_kitty = function()
  lib.run(hs.fnutils.concat(cat(), { "--instance-group=edit" }))
end

local edit_file = function(tmp, sentinel, done)
  local filename = "'" .. string.gsub(tmp, "'", "''") .. "'"
  local expr = string.format([[execute("edit " . fnameescape(%s) . " | norm! G$l")]], filename)
  lib.wait_for(NVIM_SOCK, function()
    show_edit_kitty()
    lib.run { "/opt/homebrew/bin/nvim", "--server", NVIM_SOCK, "--remote-expr", expr }
    lib.wait_for(sentinel, done)
  end)
end

local finish_edit = function(app, unlock, read, verbatim)
  local post_text = read(verbatim)
  app:activate()
  clipboard.spit(post_text, unlock)
end

local edit_in_kitty = lib.lock(function(unlock)
  local app = hs.application.frontmostApplication()
  if not app or app:name() == "kitty-quick-access" then
    unlock()
    return
  end

  clipboard.slurp(function(had_selection, pre_text)
    local tmp, sentinel, read = tmpfile(pre_text)
    edit_file(tmp, sentinel, function()
      finish_edit(app, unlock, read, had_selection)
    end)
  end)
end, show_edit_kitty)

M.init = function()
  _G.quake_hotkey = hs.hotkey.bind({ "cmd", "shift" }, "u", quake)
  _G.edit_hotkey = hs.hotkey.bind({ "cmd", "shift" }, "e", edit_in_kitty)
end

return M
