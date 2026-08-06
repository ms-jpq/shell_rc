local hunks = require "goto.checktime.hunks"
local resolve = require "goto.checktime.stages.2-resolve"
local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeActions
M.ACTIONS = {
  RETRY = "retry",
  NOOP = "noop",
  RELOAD = "reload",
  WRITE = "write",
  RECONCILE = "reconcile",
}

---@class ChecktimeRetry
---@field action "retry"

---@class ChecktimeNoop
---@field action "noop"

---@class ChecktimeReload
---@field action "reload"

---@class ChecktimeWrite
---@field action "write"
---@field version? uv.fs_stat.result

---@class ChecktimeReconcile
---@field action "reconcile"
---@field current ChecktimeCurrent
---@field text string
---@field accepted string
---@field version? uv.fs_stat.result
---@field modified boolean
---@field save boolean

---@alias ChecktimeInstruction ChecktimeRetry|ChecktimeNoop|ChecktimeReload|ChecktimeWrite|ChecktimeReconcile

---@param resolution ChecktimeResolution
---@return ChecktimeInstruction
M.compute = function(resolution)
  if resolution.kind == resolve.KINDS.RETRY then
    return { action = M.ACTIONS.RETRY }
  elseif resolution.kind == resolve.KINDS.LOCAL and not resolution.modified then
    return { action = M.ACTIONS.NOOP }
  elseif resolution.kind == resolve.KINDS.OPAQUE then
    return { action = M.ACTIONS.RELOAD }
  elseif resolution.kind == resolve.KINDS.LOCAL then
    return { action = M.ACTIONS.WRITE, version = resolution.version }
  elseif resolution.kind == resolve.KINDS.TEXT then
    local current, remote = resolution.current, resolution.remote
    local base = resolution.accepted or resolution.input or ""
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
      accepted = remote,
      version = resolution.version,
      modified = modified,
      save = modified and not resolution.input,
    }
  else
    ---@diagnostic disable-next-line: return-type-mismatch
    return assert(false, vim.inspect(resolution))
  end
end

return M
