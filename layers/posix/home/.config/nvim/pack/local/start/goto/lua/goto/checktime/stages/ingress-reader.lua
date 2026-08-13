local session = require "goto.checktime.session"
local snapshotter = require "goto.checktime.snapshotter"

local reader = {}

---@class ChecktimeReadExpectation
---@field text string

---@class ChecktimeRead
---@field buf integer
---@field assumed_base? string
---@field expected? ChecktimeReadExpectation

---@class ChecktimeReaderRetry
---@field kind "retry"
---@field buf integer
---@field session ChecktimeSession
---@field changedtick integer
---@field expected? ChecktimeReadExpectation

---@class ChecktimeReaderBase
---@field kind "base"
---@field buf integer
---@field session ChecktimeSession
---@field changedtick integer
---@field base ChecktimeBase
---@field observed? string
---@field expected? ChecktimeReadExpectation

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
    local observation, version, text = snapshotter.read(request.buf)
    if not session.finish_read(current, token) then
      return
    end
    if observation == snapshotter.OBSERVATIONS.UNSTABLE then
      done {
        kind = OBSERVATIONS.RETRY,
        buf = request.buf,
        session = current,
        changedtick = changedtick,
        expected = request.expected,
      }
    elseif observation == snapshotter.OBSERVATIONS.TEXT then
      done {
        kind = OBSERVATIONS.BASE,
        buf = request.buf,
        session = current,
        changedtick = changedtick,
        base = { text = request.assumed_base or text, version = version },
        observed = text,
        expected = request.expected,
      }
    elseif observation == snapshotter.OBSERVATIONS.OPAQUE or observation == snapshotter.OBSERVATIONS.MISSING then
      done {
        kind = OBSERVATIONS.BASE,
        buf = request.buf,
        session = current,
        changedtick = changedtick,
        base = { text = request.assumed_base, version = version },
        expected = request.expected,
      }
    else
      assert(false, vim.inspect { observation = observation, buf = request.buf })
    end
  end

  return r
end

return reader
