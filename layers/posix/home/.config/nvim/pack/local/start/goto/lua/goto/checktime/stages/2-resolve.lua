local hunks = require "goto.checktime.hunks"
local lib = require "goto.lib"
local reducer = require "goto.checktime.redux.reducer"
local session = require "goto.checktime.session"
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
---@field base? ChecktimeBase

---@class ChecktimeReconcile
---@field action "reconcile"
---@field current ChecktimeBuffer
---@field text string
---@field base ChecktimeBase
---@field modified boolean
---@field create boolean

---@alias ChecktimeInstruction ChecktimeRetry|ChecktimeNoop|ChecktimeReload|ChecktimeWrite|ChecktimeReconcile

---@class ChecktimeResolveConfig
---@field local_grace_ms integer

---@class ChecktimeResolver
---@field plan fun(buf: integer, batch: ChecktimeBatch): ChecktimeInstruction

---@param generation? ChecktimeGeneration
---@param local_grace_ms integer
---@return boolean
local within_grace = function(generation, local_grace_ms)
  return local_grace_ms > 0
    and generation ~= nil
    and vim.uv.hrtime() - generation.monotonic_ts < local_grace_ms * lib.NANOSECONDS_PER_MILLISECOND
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
    local local_change, remote_change = batch.events[reducer.CHANGES.LOCAL], batch.events[reducer.CHANGES.REMOTE]
    local local_grace = within_grace(local_change, spec.local_grace_ms)
    local buffer_modified = vim.bo[buf].modified

    if buffer_modified and local_grace then
      return { action = M.ACTIONS.RETRY }
    end
    if not remote_change then
      if buffer_modified then
        return { action = M.ACTIONS.WRITE, base = batch.base }
      end
      return { action = M.ACTIONS.NOOP }
    end

    local read, version, remote = snapshotter.read(buf)
    if read == snapshotter.STATES.RETRY then
      return { action = M.ACTIONS.RETRY }
    end
    if read == snapshotter.STATES.OPAQUE then
      return { action = buffer_modified and M.ACTIONS.RETRY or M.ACTIONS.RELOAD }
    end
    if read ~= snapshotter.STATES.RECONCILE and read ~= snapshotter.STATES.MISSING then
      ---@diagnostic disable-next-line: return-type-mismatch
      return assert(false, vim.inspect(read))
    end

    local insert_base, current = session.insert_base(buf), snapshotter.buffer(buf)
    local observed_text = remote or ""
    local base_text = snapshotter.merge_text(current, batch.base and batch.base.text or insert_base or "")
    local local_text = snapshotter.merge_text(current, current.text)
    local remote_text = snapshotter.merge_text(current, observed_text)
    if local_grace and base_text ~= remote_text then
      return { action = M.ACTIONS.RETRY }
    end

    local merged = hunks.merge(current.linefeed, base_text, local_text, remote_text)
    local text = snapshotter.buffer_text(current, merged)
    local modified = text ~= snapshotter.normalize(current, observed_text)
    return {
      action = M.ACTIONS.RECONCILE,
      current = current,
      text = text,
      base = { text = observed_text, version = version },
      modified = modified,
      create = read == snapshotter.STATES.MISSING
        and modified
        and insert_base == nil
        and not (batch.base and batch.base.version),
    }
  end

  return resolver
end

return M
