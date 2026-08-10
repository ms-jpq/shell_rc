local snapshotter = require "goto.checktime.snapshotter"

local reader = {}

---@class ChecktimeRead
---@field buf integer
---@field base? string

---@class ChecktimeReadResult: ChecktimeRead
---@field state ChecktimeReadState
---@field version? uv.fs_stat.result
---@field text? string

---@class ChecktimeReader
---@field active fun(buf: integer): boolean
---@field drop fun(buf: integer)
---@field read fun(request: ChecktimeRead)

---@param done fun(result: ChecktimeReadResult)
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
    if vim.api.nvim_buf_is_valid(request.buf) then
      done { buf = request.buf, base = request.base, state = state, version = version, text = text }
    end
  end

  return r
end

return reader
