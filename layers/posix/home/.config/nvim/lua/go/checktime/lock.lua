local async = require "go.async"
local lib = require "go.lib"

local M = {}

local cache = vim.fs.joinpath(vim.fn.stdpath "cache", "checktime")
local NANOSECONDS_PER_MILLISECOND, MILLISECONDS_PER_SECOND = 1000 * 1000, 1000
local MAX_WAIT, MAX_DELAY, MAX_JITTER = 750, 96, 24
local LEASE = 288

local milliseconds = function()
  return vim.uv.hrtime() / NANOSECONDS_PER_MILLISECOND
end

local EPOCH_OFFSET = vim.uv.gettimeofday() * MILLISECONDS_PER_SECOND - milliseconds()

local now = function()
  return EPOCH_OFFSET + milliseconds()
end

local modified = function(stat)
  return stat.mtime.sec * MILLISECONDS_PER_SECOND + stat.mtime.nsec / NANOSECONDS_PER_MILLISECOND
end

local deadline = function()
  local t0 = milliseconds()
  return function(span)
    return milliseconds() - t0 + span >= MAX_WAIT
  end
end

local signal = function(path)
  local realpath = vim.uv.fs_realpath(path)
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
    if stat and now() - modified(stat) > LEASE then
      async.uv.fs_unlink(lock)
    end
    return nil
  end

  async.uv.fs_close(fd)
  return function()
    async.uv.fs_unlink(lock)
  end
end

M.guard = function(path, fn)
  local elapsed = deadline()
  local lock = signal(path)

  for span in backoff() do
    local unlock = acquire(lock)
    if unlock then
      async.scheduled()
      lib.report(fn)
      unlock()
      async.scheduled()
      return true
    end

    if elapsed(span) then
      return false
    end
    async.sleep(span)
  end
end

return M
