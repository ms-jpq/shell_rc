local buffer_state = require "goto.checktime.buffer-state"
local poll = require "goto.checktime.watcher.poller"

local M = {}

---@class ChecktimeWatcherArgs
---@field changed fun(buf: integer, version?: uv.fs_stat.result)
---@field visible_interval integer
---@field hidden_interval integer

---@class ChecktimeWatcher
---@field attach fun(buf: integer, path: string, refresh?: boolean): boolean
---@field detach fun(buf: integer)
---@field has fun(buf: integer): boolean
---@field refresh fun(buf: integer)
---@field retry fun()
---@field update fun(buf: integer, path: string)

---@param args ChecktimeWatcherArgs
---@return ChecktimeWatcher
M.start = function(args)
  ---@diagnostic disable-next-line: missing-fields
  local watcher = {} ---@type ChecktimeWatcher
  local generation = 0

  ---@param buf integer
  ---@return integer
  local interval = function(buf)
    return #vim.fn.win_findbuf(buf) > 0 and args.visible_interval or args.hidden_interval
  end

  ---@param registration ChecktimeBufferRegistration
  local close = function(registration)
    if registration.poller then
      registration.poller.close()
      registration.poller = nil
    end
  end

  ---@param buf integer
  ---@param registration ChecktimeBufferRegistration
  local watch = function(buf, registration)
    close(registration)
    generation = generation + 1
    registration.generation = generation
    registration.interval = interval(buf)
    local current_generation = generation
    registration.poller = poll.start(registration.path, function(version)
      local current = buffer_state.registration(buf)
      if current and current.generation == current_generation then
        args.changed(buf, version)
      end
    end, registration.interval)
    registration.retry = registration.poller == nil
    buffer_state.put_registration(buf, registration)
  end

  ---@param buf integer
  watcher.detach = function(buf)
    local registration = buffer_state.registration(buf)
    if registration then
      close(registration)
      buffer_state.clear_registration(buf)
    end
  end

  ---@param buf integer
  ---@param path string
  ---@param refresh? boolean
  ---@return boolean
  watcher.attach = function(buf, path, refresh)
    local registration = buffer_state.registration(buf)
    if registration and not refresh then
      return false
    end
    watcher.detach(buf)
    registration = {
      changedtick = vim.api.nvim_buf_get_changedtick(buf),
      generation = 0,
      interval = interval(buf),
      path = path,
    }
    buffer_state.put_registration(buf, registration)
    if path ~= "" then
      watch(buf, registration)
    end
    return true
  end

  ---@param buf integer
  ---@return boolean
  watcher.has = function(buf)
    local registration = buffer_state.registration(buf)
    return registration ~= nil and registration.poller ~= nil
  end

  ---@param buf integer
  ---@param path string
  watcher.update = function(buf, path)
    local registration = buffer_state.registration(buf)
    if registration and registration.path == path and registration.interval == interval(buf) then
      if registration.retry then
        watch(buf, registration)
      end
      return
    end
    watcher.attach(buf, path, true)
  end

  ---@param buf integer
  watcher.refresh = function(buf)
    local registration = buffer_state.registration(buf)
    if registration then
      watcher.update(buf, registration.path)
    end
  end

  watcher.retry = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local registration = buffer_state.registration(buf)
      if registration and registration.retry then
        watch(buf, registration)
      end
    end
  end

  return watcher
end

return M
