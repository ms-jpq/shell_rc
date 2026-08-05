local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeControllerIO
---@field read fun(buf: integer): ChecktimeState, uv.fs_stat.result?, string?
---@field reconcile fun(buf: integer, base: string?, remote: string, version: uv.fs_stat.result?): string, uv.fs_stat.result?
---@field reload fun(buf: integer): boolean
---@field modified fun(buf: integer): boolean
---@field unchanged fun(buf: integer, version: uv.fs_stat.result?): boolean
---@field write fun(buf: integer): boolean

---@class ChecktimeController
---@field step fun(buf: integer, update: ChecktimeUpdate): boolean

---@param io ChecktimeControllerIO
---@return ChecktimeController
M.new = function(io)
  local step = function(buf, update)
    local base, version = update.base, update.version
    if update.dirty.remote then
      local state, remote_version, remote = io.read(buf)
      if state == snapshot.STATES.RETRY then
        return false
      elseif state == snapshot.STATES.OPAQUE then
        return io.reload(buf)
      elseif state == snapshot.STATES.NONE then
        base, version = io.reconcile(buf, base, "", nil)
      elseif state == snapshot.STATES.RECONCILE and remote then
        base, version = io.reconcile(buf, base, remote, remote_version)
      else
        return false
      end
    end

    if io.modified(buf) then
      return io.unchanged(buf, version) and io.write(buf)
    end
    return true
  end

  return { step = step }
end

return M
