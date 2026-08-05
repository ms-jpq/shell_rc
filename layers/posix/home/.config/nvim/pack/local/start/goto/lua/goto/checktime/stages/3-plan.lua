local hunks = require "goto.checktime.hunks"
local snapshot = require "goto.checktime.snapshot"

local M = {}

---@alias ChecktimeAction "noop"|"reconcile"|"reload"|"retry"|"write"

---@class ChecktimeActions
---@field NOOP "noop"
---@field RECONCILE "reconcile"
---@field RELOAD "reload"
---@field RETRY "retry"
---@field WRITE "write"
M.ACTIONS = {
  NOOP = "noop",
  RECONCILE = "reconcile",
  RELOAD = "reload",
  RETRY = "retry",
  WRITE = "write",
}

---@class ChecktimeNoop
---@field action "noop"

---@class ChecktimeRetry
---@field action "retry"

---@class ChecktimeReload
---@field action "reload"

---@class ChecktimeWrite
---@field action "write"
---@field version? uv.fs_stat.result
---@field force? boolean

---@class ChecktimeReconcile
---@field action "reconcile"
---@field current ChecktimeCurrent
---@field text string
---@field base string
---@field version? uv.fs_stat.result
---@field modified boolean
---@field save boolean

---@alias ChecktimeInstruction ChecktimeNoop|ChecktimeReconcile|ChecktimeReload|ChecktimeRetry|ChecktimeWrite

---@param facts ChecktimeFacts
---@return ChecktimeInstruction
M.compute = function(facts)
  if facts.batch.events.remote then
    if facts.state == snapshot.STATES.RETRY then
      return { action = M.ACTIONS.RETRY }
    elseif facts.state == snapshot.STATES.OPAQUE then
      return { action = M.ACTIONS.RELOAD }
    end

    local current = assert(facts.current)
    local remote = facts.remote or ""
    local input = facts.batch.input
    local base = input and input.base or facts.batch.base or ""
    local merged = hunks.merge(
      current.linefeed,
      snapshot.row_text(current, base),
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
      save = modified and (not input or input.closing == true),
    }
  elseif facts.modified then
    return { action = M.ACTIONS.WRITE, version = facts.batch.version }
  end
  return { action = M.ACTIONS.NOOP }
end

return M
