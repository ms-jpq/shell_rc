local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeResolutionKinds
M.KINDS = {
  LOCAL = "local",
  OPAQUE = "opaque",
  RETRY = "retry",
  TEXT = "text",
}

---@class ChecktimeResolutionRetry
---@field kind "retry"

---@class ChecktimeResolutionOpaque
---@field kind "opaque"

---@class ChecktimeResolutionText
---@field kind "text"
---@field base? string
---@field input? ChecktimeInput
---@field version? uv.fs_stat.result
---@field remote string
---@field current ChecktimeCurrent

---@class ChecktimeResolutionLocal
---@field kind "local"
---@field modified boolean
---@field version? uv.fs_stat.result

---@alias ChecktimeResolution ChecktimeResolutionLocal|ChecktimeResolutionOpaque|ChecktimeResolutionRetry|ChecktimeResolutionText

---@param buf integer
---@param batch ChecktimeBatch
---@return ChecktimeResolution
M.gather = function(buf, batch)
  if batch.events.remote then
    local state, version, remote = snapshot.read(buf)
    if state == snapshot.STATES.RETRY then
      return { kind = M.KINDS.RETRY }
    elseif state == snapshot.STATES.OPAQUE then
      return { kind = M.KINDS.OPAQUE }
    end
    return {
      kind = M.KINDS.TEXT,
      base = batch.base,
      input = batch.input,
      version = version,
      remote = remote or "",
      current = snapshot.current(buf),
    }
  end
  return { kind = M.KINDS.LOCAL, modified = vim.bo[buf].modified, version = batch.version }
end

return M
