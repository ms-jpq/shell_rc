local snapshotter = require "goto.checktime.snapshotter"

local reader = {}

---@class ChecktimeSample
---@field buf integer
---@field source string
---@field track boolean

---@class ChecktimeReader
---@field active fun(buf: integer): boolean
---@field drop fun(buf: integer)
---@field observe fun(sample: ChecktimeSample)

---@param done fun(sample: ChecktimeSample, state: ChecktimeReadState, version: uv.fs_stat.result?, text: string?)
---@return ChecktimeReader
reader.start = function(done)
  ---@diagnostic disable-next-line: missing-fields
  local reads = {} ---@type ChecktimeReader
  local latest = {} ---@type table<integer, integer>
  local sequential = 0

  ---@param buf integer
  ---@return boolean
  reads.active = function(buf)
    return latest[buf] ~= nil
  end

  ---@param buf integer
  reads.drop = function(buf)
    latest[buf] = nil
  end

  ---@param sample ChecktimeSample
  reads.observe = function(sample)
    sequential = sequential + 1
    local token = sequential
    latest[sample.buf] = token

    local state, version, text = snapshotter.read(sample.buf)
    if latest[sample.buf] ~= token then
      return
    end
    latest[sample.buf] = nil
    if vim.api.nvim_buf_is_valid(sample.buf) then
      done(sample, state, version, text)
    end
  end

  return reads
end

return reader
