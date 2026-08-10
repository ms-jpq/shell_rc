local hunks = require "goto.checktime.hunks"
local lib = require "goto.lib"
local reducer = require "goto.checktime.reducer"
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
---@field current ChecktimeBuffer
---@field text string
---@field base string
---@field modified boolean
---@field save boolean
---@field version? uv.fs_stat.result

---@alias ChecktimeInstruction ChecktimeRetry|ChecktimeNoop|ChecktimeReload|ChecktimeWrite|ChecktimeReconcile

---@class ChecktimeResolveConfig
---@field grace_ms integer

---@class ChecktimeResolver
---@field plan fun(buf: integer, batch: ChecktimeBatch): ChecktimeInstruction

---@param generation? ChecktimeGeneration
---@param grace_ms integer
---@return boolean
local within_grace = function(generation, grace_ms)
  return generation ~= nil and vim.uv.hrtime() - generation.monotonic_ts < grace_ms * lib.NANOSECONDS_PER_MILLISECOND
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
    local local_grace = within_grace(local_change, spec.grace_ms)
    local buffer_modified = vim.bo[buf].modified

    if buffer_modified and local_grace then
      return { action = M.ACTIONS.RETRY }
    end
    if not remote_change then
      if buffer_modified then
        return { action = M.ACTIONS.WRITE, version = batch.version }
      end
      return { action = M.ACTIONS.NOOP }
    end

    local read, version, remote = snapshotter.read(buf)
    if read == snapshotter.STATES.RETRY then
      return { action = M.ACTIONS.RETRY }
    end
    if read == snapshotter.STATES.OPAQUE then
      return { action = M.ACTIONS.RELOAD }
    end
    if read ~= snapshotter.STATES.RECONCILE and read ~= snapshotter.STATES.MISSING then
      ---@diagnostic disable-next-line: return-type-mismatch
      return assert(false, vim.inspect(read))
    end

    local insert_base, current = snapshotter.insert_base(buf), snapshotter.buffer(buf)
    local remote_base = remote or ""
    local common_base = snapshotter.merge_text(current, batch.base or insert_base or "")
    local remote_text = snapshotter.merge_text(current, remote_base)
    if local_grace and common_base ~= remote_text then
      return { action = M.ACTIONS.RETRY }
    end

    local merged =
      hunks.merge(current.linefeed, common_base, snapshotter.merge_text(current, current.text), remote_text)
    local text = snapshotter.buffer_text(current, merged)
    local modified = text ~= snapshotter.normalize(current, remote_base)
    return {
      action = M.ACTIONS.RECONCILE,
      current = current,
      text = text,
      base = remote_base,
      version = version,
      modified = modified,
      save = modified and insert_base == nil,
    }
  end

  return resolver
end

return M
