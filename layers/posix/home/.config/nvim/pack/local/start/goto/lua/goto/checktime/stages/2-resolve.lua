local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeFacts
---@field batch ChecktimeBatch
---@field events ChecktimeEvents
---@field modified boolean
---@field state? ChecktimeState
---@field version? uv.fs_stat.result
---@field remote? string
---@field current? ChecktimeCurrent

---@param buf integer
---@param batch ChecktimeBatch
---@param events ChecktimeEvents
---@return ChecktimeFacts
M.gather = function(buf, batch, events)
  local facts = { batch = batch, events = events, modified = vim.bo[buf].modified } ---@type ChecktimeFacts
  if events.remote then
    facts.state, facts.version, facts.remote = snapshot.read(buf)
    if facts.state == snapshot.STATES.RECONCILE or facts.state == snapshot.STATES.NONE then
      facts.current = snapshot.current(buf)
    end
  end
  return facts
end

return M
