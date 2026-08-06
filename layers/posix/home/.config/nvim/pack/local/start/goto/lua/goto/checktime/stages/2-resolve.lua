local hunks = require "goto.checktime.hunks"
local lib = require "goto.lib"
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
---@field modified boolean
---@field save boolean
---@field version? uv.fs_stat.result

---@alias ChecktimeInstruction ChecktimeRetry|ChecktimeNoop|ChecktimeReload|ChecktimeWrite|ChecktimeReconcile

---@class ChecktimeResolveConfig
---@field grace_ms integer

---@class ChecktimeResolver
---@field plan fun(buf: integer, batch: ChecktimeBatch): ChecktimeInstruction

---@param batch ChecktimeBatch
---@param grace_ms integer
---@return boolean
local within_grace = function(batch, grace_ms)
  local local_change = batch.events["local"]
  return local_change ~= nil
    and batch.events.remote ~= nil
    and vim.uv.hrtime() - local_change.monotonic_ts < grace_ms * lib.NANOSECONDS_PER_MILLISECOND
end

---@param spec ChecktimeResolveConfig
---@return ChecktimeResolver
M.start = function(spec)
  ---@diagnostic disable-next-line: missing-fields
  local resolver = {} ---@type ChecktimeResolver

  ---@param buf integer
  ---@param batch ChecktimeBatch
  ---@return ChecktimeInstruction
  resolver.plan = function(buf, batch)
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
      local input, current = snapshotter.input(buf), snapshotter.current(buf)
      local accepted = remote or ""
      local base = snapshotter.row_text(current, batch.accepted or input or "")
      local remote_text = snapshotter.row_text(current, accepted)

      if within_grace(batch, spec.grace_ms) and base ~= remote_text then
        return { action = M.ACTIONS.RETRY }
      end

      local merged = hunks.merge(current.linefeed, base, snapshotter.row_text(current, current.text), remote_text)
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

  return resolver
end

return M
