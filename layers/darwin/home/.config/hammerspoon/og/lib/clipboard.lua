local M = {}

M.preserve = function(fn)
  local prev = hs.pasteboard.readAllData()
  local ok, result = pcall(fn)
  hs.pasteboard.writeAllData(prev)
  if not ok then
    error(result)
  end
  return result
end

M.copy_selection = function()
  hs.pasteboard.setContents ""
  local before = hs.pasteboard.changeCount()
  hs.eventtap.keyStroke({ "cmd" }, "c", 0)
  for _ = 1, 20 do
    if hs.pasteboard.changeCount() ~= before then
      break
    end
    hs.timer.usleep(5 * 1000)
  end
  return hs.pasteboard.getContents() or ""
end

M.slurp = function()
  return M.preserve(function()
    local text = M.copy_selection()
    if text == "" then
      hs.eventtap.keyStroke({ "cmd" }, "a", 0)
      text = M.copy_selection()
    end
    return text
  end)
end

M.spit = function(text)
  local prev = hs.pasteboard.readAllData()
  hs.pasteboard.setContents(text)
  hs.eventtap.keyStroke({ "cmd" }, "v", 0)
  hs.timer.doAfter(0.3, function()
    hs.pasteboard.writeAllData(prev)
  end)
end

return M
