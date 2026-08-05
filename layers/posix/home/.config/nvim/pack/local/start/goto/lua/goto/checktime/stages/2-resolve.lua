local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeReadRetry
---@field state "retry"

---@class ChecktimeReadOpaque
---@field state "opaque"

---@class ChecktimeReadText
---@field state "reconcile"|"none"
---@field version? uv.fs_stat.result
---@field remote string
---@field current ChecktimeCurrent

---@alias ChecktimeRead ChecktimeReadOpaque|ChecktimeReadRetry|ChecktimeReadText

---@class ChecktimeFacts
---@field batch ChecktimeBatch
---@field modified boolean
---@field read? ChecktimeRead

---@param buf integer
---@param batch ChecktimeBatch
---@return ChecktimeFacts
M.gather = function(buf, batch)
  local facts = {
    batch = batch,
    modified = vim.bo[buf].modified,
  } ---@type ChecktimeFacts

  if batch.events.remote then
    local state, version, remote = snapshot.read(buf)
    if state == snapshot.STATES.RETRY or state == snapshot.STATES.OPAQUE then
      facts.read = { state = state }
    else
      facts.read = {
        state = state,
        version = version,
        remote = remote or "",
        current = snapshot.current(buf),
      }
    end
  end
  return facts
end

return M
