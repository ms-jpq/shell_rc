local hunks = require "goto.checktime.hunks"
local snapshot = require "goto.checktime.snapshot"

local M = {}

---@alias ChecktimeAction "noop"|"reconcile"|"reload"|"retry"|"write"

---@class ChecktimeActions
---@field NOOP ChecktimeAction
---@field RECONCILE ChecktimeAction
---@field RELOAD ChecktimeAction
---@field RETRY ChecktimeAction
---@field WRITE ChecktimeAction
M.ACTIONS = {
  NOOP = "noop",
  RECONCILE = "reconcile",
  RELOAD = "reload",
  RETRY = "retry",
  WRITE = "write",
}

---@class ChecktimeInstruction
---@field action ChecktimeAction
---@field current? ChecktimeCurrent
---@field text? string
---@field base? string
---@field version? uv.fs_stat.result
---@field modified? boolean
---@field save? boolean
---@field force? boolean
---@field changedtick? integer

---@param facts ChecktimeFacts
---@return ChecktimeInstruction
M.compute = function(facts)
  if facts.stale then
    return { action = M.ACTIONS.RETRY }
  elseif facts.events.remote then
    if facts.state == snapshot.STATES.RETRY then
      return { action = M.ACTIONS.RETRY }
    elseif facts.state == snapshot.STATES.OPAQUE then
      local local_order, remote_order = facts.events["local"] or 0, facts.events.remote
      return {
        action = local_order > remote_order and M.ACTIONS.WRITE or M.ACTIONS.RELOAD,
        force = true,
        changedtick = facts.changedtick,
      }
    end

    local current = assert(facts.current)
    local remote = facts.remote or ""
    local merged = hunks.merge(
      current.linefeed,
      snapshot.row_text(current, facts.batch.base or ""),
      snapshot.row_text(current, current.text),
      snapshot.row_text(current, remote)
    )
    local text = snapshot.buffer_text(current, merged)
    local modified = text ~= snapshot.fit(current, remote)
    return {
      action = M.ACTIONS.RECONCILE,
      current = current,
      text = text,
      base = remote,
      version = facts.version,
      modified = modified,
      save = modified,
      changedtick = facts.changedtick,
    }
  elseif facts.modified then
    return { action = M.ACTIONS.WRITE, version = facts.batch.version, changedtick = facts.changedtick }
  end
  return { action = M.ACTIONS.NOOP }
end

return M
