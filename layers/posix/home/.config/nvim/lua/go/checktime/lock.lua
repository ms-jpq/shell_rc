local async = require "go.async"
local lib = require "go.lib"

local M = {}

local cache = vim.fs.joinpath(vim.fn.stdpath "cache", "checktime")
local MAX_WAIT = 750
local MAX_DELAY, MAX_JITTER = 96, 24
local STALE_AFTER = 3
local MODE = tonumber("600", 8)

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
    local jitter = math.floor((vim.uv.hrtime() / 1000000) % (MAX_JITTER + 1))
    return delay + jitter
  end
end

local acquire = function(lock)
  local _, fd = async.uv.fs_open(lock, "wx", MODE)
  if not fd then
    local _, stat = async.uv.fs_stat(lock)
    if stat and stat.mtime.sec + STALE_AFTER < os.time() then
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
  local t0 = vim.uv.hrtime()
  local lock = signal(path)

  local unlock = nil
  for span in backoff() do
    unlock = acquire(lock)
    if unlock then
      async.scheduled()
      lib.report(fn)
      break
    end

    if vim.uv.hrtime() - t0 + span * 1000000 >= MAX_WAIT * 1000000 then
      break
    end
    async.sleep(span)
  end

  if not unlock then
    return false
  end

  unlock()
  async.scheduled()
  return true
end

return M
