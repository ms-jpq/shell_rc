local async = require "goto.async"
local lib = require "goto.lib"
local poll = require "goto.checktime.watcher.poller"

local M = {}

local WATCH = "__checktime_watcher__"

---@class ChecktimeWatcherArgs
---@field changed fun(buf: integer)
---@field reloading fun(buf: integer): boolean

---@class ChecktimeWatcher
---@field has fun(buf: integer): boolean
---@field retry fun()
---@field update fun(buf: integer, path: string)

---@class ChecktimeWatch
---@field path string
---@field poller? ChecktimePoller

---@param args ChecktimeWatcherArgs
---@return ChecktimeWatcher
M.start = function(args)
  ---@diagnostic disable-next-line: missing-fields
  local watcher = {} ---@type ChecktimeWatcher

  ---@param buf integer
  ---@param path string
  local start = function(buf, path)
    local entry = poll.start(
      path,
      vim.schedule_wrap(async(function()
        if vim.api.nvim_buf_is_valid(buf) then
          local current = vim.b[buf][WATCH]
          if current and current.path == path then
            args.changed(buf)
          end
        end
      end))
    )
    vim.b[buf][WATCH] = { path = path, poller = entry }
  end

  ---@param buf integer
  local reap = function(buf)
    local current = vim.b[buf][WATCH]
    if current and current.poller then
      current.poller.close()
    end
    vim.b[buf][WATCH] = nil
  end

  ---@param buf integer
  ---@return boolean
  watcher.has = function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.b[buf][WATCH] ~= nil
  end

  watcher.retry = function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      local current = vim.b[buf][WATCH]
      if current and not current.poller then
        start(buf, current.path)
      end
    end
  end

  ---@param buf integer
  ---@param path string
  watcher.update = function(buf, path)
    local previous = vim.b[buf][WATCH]
    if previous and previous.path == path then
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
