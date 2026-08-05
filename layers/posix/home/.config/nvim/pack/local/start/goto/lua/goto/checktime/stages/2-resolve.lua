local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeFacts
---@field batch ChecktimeBatch
---@field modified boolean
---@field state? ChecktimeState
---@field version? uv.fs_stat.result
---@field remote? string
---@field current? ChecktimeCurrent

---@param buf integer
---@param batch ChecktimeBatch
---@return ChecktimeFacts
M.gather = function(buf, batch)
  local facts = {
    batch = batch,
    modified = vim.bo[buf].modified,
  } ---@type ChecktimeFacts

  if batch.events.remote then
    facts.state, facts.version, facts.remote = snapshot.read(buf)
    if facts.state == snapshot.STATES.RECONCILE or facts.state == snapshot.STATES.NONE then
      facts.current = snapshot.current(buf)
    end
  end
  return facts
end

return M
