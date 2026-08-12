local session = require "goto.checktime.session"
local snapshotter = require "goto.checktime.snapshotter"

local reader = {}

---@class ChecktimeRead
---@field buf integer
---@field initial? string

---@class ChecktimeReaderRetry
---@field kind "retry"
---@field buf integer
---@field session ChecktimeSession
---@field changedtick integer

---@class ChecktimeReaderBase
---@field kind "base"
---@field buf integer
---@field session ChecktimeSession
---@field changedtick integer
---@field base ChecktimeBase
---@field observed? string

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

  ---@param buf integer
  ---@return boolean
  r.active = function(buf)
    return session.reading(buf)
  end

  ---@param buf integer
  r.drop = function(buf)
    session.cancel_read(buf)
  end

  ---@param request ChecktimeRead
  r.read = function(request)
    local current, token = session.begin_read(request.buf)
    if not current or not token then
      return
    end

    local changedtick = vim.api.nvim_buf_get_changedtick(request.buf)
    local state, version, text = snapshotter.read(request.buf)
    if not session.finish_read(current, token) then
      return
    end
    if state == snapshotter.STATES.RETRY then
      done { kind = OBSERVATIONS.RETRY, buf = request.buf, session = current, changedtick = changedtick }
    elseif state == snapshotter.STATES.RECONCILE then
      done {
        kind = OBSERVATIONS.BASE,
        buf = request.buf,
        session = current,
        changedtick = changedtick,
        base = { text = request.initial or text, version = version },
        observed = text,
      }
    elseif state == snapshotter.STATES.OPAQUE or state == snapshotter.STATES.MISSING then
      done {
        kind = OBSERVATIONS.BASE,
        buf = request.buf,
        session = current,
        changedtick = changedtick,
        base = { text = request.initial, version = version },
      }
    else
      assert(false, vim.inspect { state = state, buf = request.buf })
    end
  end

  return r
end

return reader
