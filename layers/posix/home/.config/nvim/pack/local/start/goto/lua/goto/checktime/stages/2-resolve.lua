local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeResolutionKinds
M.KINDS = {
  LOCAL = "local",
  OPAQUE = "opaque",
  RETRY = "retry",
  TEXT = "text",
}

local text = function(buf, batch, version, remote)
  return {
    kind = M.KINDS.TEXT,
    accepted = batch.accepted,
    version = version,
    remote = remote or "",
    current = snapshot.current(buf),
  }
end

---@class ChecktimeResolutionRetry
---@field kind "retry"

---@class ChecktimeResolutionOpaque
---@field kind "opaque"

---@class ChecktimeResolutionText
---@field kind "text"
---@field accepted? string
---@field input? string
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
  if not batch.events.remote then
    return { kind = M.KINDS.LOCAL, modified = vim.bo[buf].modified, version = batch.version }
  end

  local state, version, remote = snapshot.read(buf)
  if state == snapshot.STATES.RETRY then
    return { kind = M.KINDS.RETRY }
  elseif state == snapshot.STATES.OPAQUE then
    return { kind = M.KINDS.OPAQUE }
  elseif state == snapshot.STATES.RECONCILE then
    local resolution = text(buf, batch, version, remote)
    resolution.input = snapshot.input(buf)
    return resolution
  elseif state == snapshot.STATES.NONE then
    local resolution = text(buf, batch, version, remote)
    resolution.input = snapshot.input(buf)
    return resolution
  else
    ---@diagnostic disable-next-line: return-type-mismatch
    return assert(false, vim.inspect(state))
  end
end

return M
