local snapshotter = require "goto.checktime.snapshotter"

local reader = {}

---@class ChecktimeRead
---@field buf integer
---@field base? string

---@class ChecktimeReaderRetry
---@field kind "retry"
---@field buf integer

---@class ChecktimeReaderBase
---@field kind "base"
---@field buf integer
---@field base ChecktimeBase

---@alias ChecktimeReaderObservation ChecktimeReaderRetry|ChecktimeReaderBase

local OBSERVATIONS = {
  RETRY = "retry",
  BASE = "base",
}
reader.OBSERVATIONS = OBSERVATIONS

---@class ChecktimeReader
---@field active fun(buf: integer): boolean
---@field drop fun(buf: integer)
---@field read fun(request: ChecktimeRead)

---@param done fun(observation: ChecktimeReaderObservation)
---@return ChecktimeReader
reader.start = function(done)
  ---@diagnostic disable-next-line: missing-fields
  local r = {} ---@type ChecktimeReader

  local latest = {} ---@type table<integer, integer>
  local sequential = 0

  ---@param buf integer
  ---@return boolean
  r.active = function(buf)
    return latest[buf] ~= nil
  end

  ---@param buf integer
  r.drop = function(buf)
    latest[buf] = nil
  end

  ---@param request ChecktimeRead
  r.read = function(request)
    sequential = sequential + 1
    local token = sequential
    latest[request.buf] = token

    local state, version, text = snapshotter.read(request.buf)
    if latest[request.buf] ~= token then
      return
    end
    latest[request.buf] = nil
    if not vim.api.nvim_buf_is_valid(request.buf) then
      return
    elseif state == snapshotter.STATES.RETRY then
      done { kind = OBSERVATIONS.RETRY, buf = request.buf }
    elseif state == snapshotter.STATES.RECONCILE then
      done { kind = OBSERVATIONS.BASE, buf = request.buf, base = { text = request.base or text, version = version } }
    elseif state == snapshotter.STATES.OPAQUE or state == snapshotter.STATES.MISSING then
      done { kind = OBSERVATIONS.BASE, buf = request.buf, base = { text = request.base, version = version } }
    else
      assert(false, vim.inspect { state = state, buf = request.buf })
    end
  end

  return r
end

return reader
