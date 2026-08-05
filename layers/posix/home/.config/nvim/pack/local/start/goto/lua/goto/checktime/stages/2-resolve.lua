local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeFacts
---@field batch ChecktimeBatch
---@field events ChecktimeEvents
---@field modified boolean
---@field changedtick integer
---@field stale? boolean
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
    events = batch.events,
    modified = vim.bo[buf].modified,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
  } ---@type ChecktimeFacts

  if batch.changedtick and batch.changedtick ~= facts.changedtick then
    facts.stale = true
    return facts
  end

  if batch.events.remote then
    facts.state, facts.version, facts.remote = snapshot.read(buf)
    if facts.state == snapshot.STATES.RECONCILE or facts.state == snapshot.STATES.NONE then
      facts.current = snapshot.current(buf)
      facts.changedtick = facts.current.changedtick
    end
  end
  return facts
end

return M
