local hunks = require "goto.checktime.hunks"
local snapshotter = require "goto.checktime.snapshotter"

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

---@param buf integer
---@param batch ChecktimeBatch
---@return ChecktimeInstruction
M.plan = function(buf, batch)
  if not batch.events.remote then
    if vim.bo[buf].modified then
      return { action = M.ACTIONS.WRITE, version = batch.version }
    else
      return { action = M.ACTIONS.NOOP }
    end
  end

  local state, version, remote = snapshotter.read(buf)
  if state == snapshotter.STATES.RETRY then
    return { action = M.ACTIONS.RETRY }
  elseif state == snapshotter.STATES.OPAQUE then
    return { action = M.ACTIONS.RELOAD }
  elseif state == snapshotter.STATES.RECONCILE or state == snapshotter.STATES.NONE then
    local input = snapshotter.input(buf)
    local current = snapshotter.current(buf)
    local accepted = remote or ""
    local merged = hunks.merge(
      current.linefeed,
      snapshotter.row_text(current, batch.accepted or input or ""),
      snapshotter.row_text(current, current.text),
      snapshotter.row_text(current, accepted)
    )
    local text = snapshotter.buffer_text(current, merged)
    local modified = text ~= snapshotter.fit(current, accepted)
    return {
      action = M.ACTIONS.RECONCILE,
      current = current,
      text = text,
      accepted = accepted,
      version = version,
      modified = modified,
      save = modified and input == nil,
    }
  else
    ---@diagnostic disable-next-line: return-type-mismatch
    return assert(false, vim.inspect(state))
  end
end

return M
