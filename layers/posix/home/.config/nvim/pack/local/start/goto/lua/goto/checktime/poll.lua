local M = {}

---@class ChecktimePoller
---@field path string
---@field bufs table<integer, true>
---@field close fun()

---@param path string
---@param bufs table<integer, true>
---@param changed fun()
---@return ChecktimePoller?
M.start = function(path, bufs, changed)
  local handle = vim.uv.new_fs_poll()
  if not handle then
    return nil
  end
  if not handle:start(path, 99, changed) then
    handle:close()
    return nil
  end

  ---@diagnostic disable-next-line: missing-fields
  local watcher = { path = path, bufs = bufs } ---@type ChecktimePoller
  watcher.close = function()
    handle:stop()
    handle:close()
  end
  return watcher
end

return M
