local hunks = require "goto.checktime.hunks"
local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeNoop
---@field action "noop"

---@class ChecktimeRetry
---@field action "retry"

---@class ChecktimeReload
---@field action "reload"

---@class ChecktimeWrite
---@field action "write"
---@field version? uv.fs_stat.result

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
  local read = facts.read
  if read then
    if read.state == snapshot.STATES.RETRY then
      return { action = "retry" }
    elseif read.state == snapshot.STATES.OPAQUE then
      return { action = "reload" }
    end

    local current, remote = read.current, read.remote
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
      action = "reconcile",
      current = current,
      text = text,
      base = remote,
      version = read.version,
      modified = modified,
      save = modified and (not input or input.closing == true),
    }
  elseif facts.modified then
    return { action = "write", version = facts.batch.version }
  end
  return { action = "noop" }
end

return M
