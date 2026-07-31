local lib = require "togo.lib"

local M = {}

local poll_copy = nil
poll_copy = function(before, remaining, done)
  if hs.pasteboard.changeCount() ~= before then
    done(hs.pasteboard.getContents() or "")
    return
  end
  if remaining <= 0 then
    done ""
    return
  end

  hs.timer.doAfter(0.005, function()
    if poll_copy then
      poll_copy(before, remaining - 1, done)
    end
  end)
end

local preserve = lib.lock(function(unlock, fn, done)
  local prev = hs.pasteboard.readAllData()
  local finish = function(...)
    hs.pasteboard.writeAllData(prev)
    unlock()
    if done then
      done(...)
    end
  end

  local ok, err = pcall(fn, finish)
  if not ok then
    hs.pasteboard.writeAllData(prev)
    unlock()
    error(err)
  end
end)

M.copy_selection = function(done)
  hs.pasteboard.setContents ""
  local before = hs.pasteboard.changeCount()
  hs.eventtap.keyStroke({ "cmd" }, "c", 0)
  poll_copy(before, 20, done)
end

M.slurp = function(done)
  preserve(function(finish)
    M.copy_selection(function(text)
      if text ~= "" then
        finish(true, text)
        return
      end

      hs.eventtap.keyStroke({ "cmd" }, "a", 0)
      M.copy_selection(function(all)
        finish(false, all)
      end)
    end)
  end, done)
end

M.spit = function(text, done)
  preserve(function(finish)
    hs.pasteboard.setContents(text)
    hs.eventtap.keyStroke({ "cmd" }, "v", 0)
    hs.timer.doAfter(0.3, finish)
  end, done)
end

return M
