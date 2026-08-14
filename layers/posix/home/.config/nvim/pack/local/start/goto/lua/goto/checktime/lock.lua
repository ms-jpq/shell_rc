local async = require "goto.async"
local lib = require "goto.lib"

local M = {}

---@alias ChecktimeUnlock fun()

local cache = vim.fs.joinpath(vim.fn.stdpath "cache", "checktime")
local MAX_WAIT, MAX_DELAY, MAX_JITTER = 750, 96, 24
local LEASE = 3 * 1000

local milliseconds = function()
  return lib.ns_to_ms(vim.uv.hrtime())
end

local EPOCH_OFFSET = (function()
  local seconds, microseconds = vim.uv.gettimeofday()
  return lib.seconds_to_ms(assert(seconds)) + lib.microseconds_to_ms(assert(tonumber(microseconds))) - milliseconds()
end)()

local deadline = function()
  local t0 = milliseconds()
  return function(span)
    return milliseconds() - t0 + span >= MAX_WAIT
  end
end

local signal = function(path)
  local _, realpath = async.uv.fs_realpath(path)
  async.scheduled()
  realpath = realpath or path
  return vim.fs.joinpath(cache, vim.fn.sha256(realpath) .. ".lock")
end

local backoff = function()
  local attempts = 0
  return function()
    attempts = attempts + 1
    local delay = math.min(MAX_DELAY - MAX_JITTER, 8 * 2 ^ math.min(attempts, 4))
    local jitter = math.floor(milliseconds() % (MAX_JITTER + 1))
    return delay + jitter
  end
end

local acquire = function(lock)
  local _, fd = async.uv.fs_open(lock, "wx", tonumber("600", 8))
  if not fd then
    local _, stat = async.uv.fs_stat(lock)
    local now = EPOCH_OFFSET + milliseconds()
    local modified = stat and (lib.seconds_to_ms(stat.mtime.sec) + lib.ns_to_ms(stat.mtime.nsec))
    if modified and now - modified > LEASE then
      async.uv.fs_unlink(lock)
    end
    return nil
  end

  async.uv.fs_close(fd)
  return function()
    async.uv.fs_unlink(lock)
  end
end

---@generic T
---@param path string
---@param fn fun()
M.guard = function(path, fn)
  vim.fn.mkdir(cache, "p")
  return lib.scope(function(defer)
    defer(async.scheduled)
    local elapsed = deadline()
    local lock = signal(path)

    for span in backoff() do
      local unlock = acquire(lock)
      if unlock then
        async.scheduled()
        local completed
        local reported = lib.report(function()
          lib.scope(function(d)
            d(async.scheduled)
            completed = fn()
          end)
        end)
        unlock()
        if reported then
          return completed
        end
        return nil
      end

      if elapsed(span) then
        return nil
      end
      async.sleep(span)
    end
  end)
end

return M
