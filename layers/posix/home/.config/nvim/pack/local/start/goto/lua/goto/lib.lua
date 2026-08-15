-- https://github.com/luvit/luv/blob/master/docs/docs.md

local async = require "goto.async"
local libexec = require "goto.libexec"

local M = {}
local MILLISECONDS_PER_SECOND = 1000
local NANOSECONDS_PER_MILLISECOND = 1000 * 1000

M.LF = "\n"

---@param mode string
---@return boolean
M.is_insert = function(mode)
  return string.find(mode, "^[iR]") ~= nil or string.find(mode, "^ni[IRV]") ~= nil
end

---@param milliseconds number
---@return number
M.ms_to_ns = function(milliseconds)
  return milliseconds * NANOSECONDS_PER_MILLISECOND
end

---@param nanoseconds number
---@return number
M.ns_to_ms = function(nanoseconds)
  return nanoseconds / NANOSECONDS_PER_MILLISECOND
end

---@param seconds number
---@return number
M.seconds_to_ms = function(seconds)
  return seconds * MILLISECONDS_PER_SECOND
end

---@param microseconds number
---@return number
M.microseconds_to_ms = function(microseconds)
  return microseconds / MILLISECONDS_PER_SECOND
end

M.clamp = function(lo, self, hi)
  return math.max(lo, math.min(self, hi))
end

---@generic T: table
---@param value T
---@param changes? table
---@return T
M.copy = function(value, changes)
  return vim.tbl_extend("force", {}, value, changes or {})
end

do
  M.group = vim.api.nvim_create_augroup([[lv_goto]], { clear = true })
end

M.is_win = vim.fn.has [[win64]] == 1
  or vim.fn.has [[win64unix]] == 1
  or vim.fn.has [[win32]] == 1
  or vim.fn.has [[win32unix]] == 1

M.is_linux = vim.fn.has [[linux]] == 1

M.os = {
  sep = M.is_win and [[\]] or [[/]],
}

M.report = function(fn, ...)
  local ok, err = xpcall(fn, debug.traceback, ...)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
  return ok
end

M.generation = function(name)
  local key = "__goto_gen_" .. name
  _G[key] = (_G[key] or 0) + 1
  local mine = _G[key]
  return function()
    return _G[key] == mine
  end
end

M.scope = function(fn)
  local defers = {}
  local ok, ret = xpcall(fn, debug.traceback, function(defer)
    table.insert(defers, defer)
  end)

  for defer in vim.iter(defers):rev() do
    M.report(defer)
  end

  if ok then
    return ret
  else
    error(ret, 0)
  end
end

do
  local STATE = {
    idle = 1,
    running = 2,
    pending = 3,
  }
  M.throttle = function(delay, fn)
    local wrapped = async(fn)

    local run = function(args)
      M.report(wrapped, unpack(args))
    end

    local argv = {}
    local state = STATE.idle
    return function(...)
      argv = { ... }
      if state ~= STATE.idle then
        state = STATE.pending
        return
      end

      state = STATE.running
      run(argv)

      async.run(function()
        async.sleep(delay)
        while state == STATE.pending do
          state = STATE.running
          run(argv)
          async.sleep(delay)
        end
        state = STATE.idle
      end)
    end
  end
end

M.read_json = function(path)
  local json = vim.fn.readblob(path)
  return libexec.json_decode(json)
end

M.buf_linefeed = function(buf)
  local ff = vim.bo[buf].fileformat

  if ff == "dos" then
    return "\r\n"
  elseif ff == "unix" then
    return M.LF
  elseif ff == "mac" then
    return "\r"
  else
    assert(false, ff)
  end
end

M.keepalt_buffer = function(buf)
  vim.cmd.buffer { tostring(buf), mods = { keepalt = true } }
end

return M
