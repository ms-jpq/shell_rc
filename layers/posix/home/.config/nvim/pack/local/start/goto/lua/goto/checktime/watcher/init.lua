local async = require "goto.async"
local lib = require "goto.lib"
local poll = require "goto.checktime.watcher.poller"

local M = {}

local WATCH = "__checktime_watcher__"

---@class ChecktimeWatcherArgs
---@field changed fun(buf: integer)
---@field visible_interval integer
---@field hidden_interval integer
---@field reloading fun(buf: integer): boolean

---@class ChecktimeWatcher
---@field has fun(buf: integer): boolean
---@field refresh fun(buf: integer)
---@field retry fun()
---@field update fun(buf: integer, path: string)

---@class ChecktimeWatch
---@field path string
---@field poller? ChecktimePoller
---@field interval integer

---@param args ChecktimeWatcherArgs
---@return ChecktimeWatcher
M.start = function(args)
  ---@diagnostic disable-next-line: missing-fields
  local watcher = {} ---@type ChecktimeWatcher
  local retrying = {} ---@type table<integer, true>

  ---@param buf integer
  ---@return integer
  local interval = function(buf)
    return #vim.fn.win_findbuf(buf) > 0 and args.visible_interval or args.hidden_interval
  end

  ---@param buf integer
  ---@param path string
  local start = function(buf, path)
    local period = interval(buf)
    local entry = poll.start(
      path,
      vim.schedule_wrap(async(function()
        if vim.api.nvim_buf_is_valid(buf) then
          local current = vim.b[buf][WATCH]
          if current and current.path == path then
            args.changed(buf)
          end
        end
      end)),
      period
    )
    vim.b[buf][WATCH] = { path = path, poller = entry, interval = period }
    retrying[buf] = entry and nil or true
  end

  ---@param buf integer
  local reap = function(buf)
    local current = vim.b[buf][WATCH]
    if current and current.poller then
      current.poller.close()
    end
    vim.b[buf][WATCH] = nil
    retrying[buf] = nil
  end

  ---@param buf integer
  ---@return boolean
  watcher.has = function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.b[buf][WATCH] ~= nil
  end

  watcher.retry = function()
    for buf in pairs(retrying) do
      if not vim.api.nvim_buf_is_valid(buf) then
        retrying[buf] = nil
      else
        local current = vim.b[buf][WATCH]
        if current and not current.poller then
          start(buf, current.path)
        else
          retrying[buf] = nil
        end
      end
    end
  end

  ---@param buf integer
  watcher.refresh = function(buf)
    local current = vim.b[buf][WATCH]
    if current then
      watcher.update(buf, current.path)
    end
  end

  ---@param buf integer
  ---@param path string
  watcher.update = function(buf, path)
    local previous = vim.b[buf][WATCH]
    if previous and previous.path == path and previous.interval == interval(buf) then
      if not previous.poller then
        start(buf, path)
      end
      return
    end
    reap(buf)
    if path ~= "" then
      start(buf, path)
    end
  end

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(event)
      if not args.reloading(event.buf) then
        reap(event.buf)
      end
    end,
  })

  return watcher
end

return M
