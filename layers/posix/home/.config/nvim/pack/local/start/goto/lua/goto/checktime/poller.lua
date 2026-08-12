local M = {}

---@class ChecktimePoller
---@field path string
---@field close fun()

---@param path string
---@param changed fun(current?: uv.fs_stat.result)
---@param interval integer
---@return ChecktimePoller?
M.start = function(path, changed, interval)
  local handle = vim.uv.new_fs_poll()
  if not handle then
    return nil
  end
  if
    not handle:start(
      path,
      interval,
      vim.schedule_wrap(function(_, _, current)
        changed(current)
      end)
    )
  then
    handle:close()
    return nil
  end

  ---@diagnostic disable-next-line: missing-fields
  local p = { path = path } ---@type ChecktimePoller

  p.close = function()
    handle:stop()
    handle:close()
  end
  return p
end

return M
