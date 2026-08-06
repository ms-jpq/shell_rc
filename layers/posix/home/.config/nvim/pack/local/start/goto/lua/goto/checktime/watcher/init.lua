local async = require "goto.async"
local poll = require "goto.checktime.watcher.poller"

local M = {}

---@class ChecktimeWatcherArgs
---@field changed fun(buf: integer)

---@class ChecktimeWatcher
---@field has fun(buf: integer): boolean
---@field refresh fun()
---@field retry fun()
---@field update fun(buf: integer, path: string)

---@param args ChecktimeWatcherArgs
---@return ChecktimeWatcher
M.start = function(args)
  local attachments = {} ---@type table<integer, string>
  local entries = {} ---@type table<string, ChecktimePoller>
  ---@diagnostic disable-next-line: missing-fields
  local watcher = {} ---@type ChecktimeWatcher

  ---@param path string
  local close = function(path)
    for _, attached in pairs(attachments) do
      if attached == path then
        return
      end
    end
    local entry = entries[path]
    if entry then
      entry.close()
      entries[path] = nil
    end
  end

  ---@param path string
  local start = function(path)
    if entries[path] then
      return
    end
    local entry = poll.start(
      path,
      vim.schedule_wrap(async(function()
        for buf, attached in pairs(attachments) do
          if attached == path then
            args.changed(buf)
          end
        end
      end))
    )
    if entry then
      entries[path] = entry
    end
  end

  ---@param buf integer
  ---@return boolean
  watcher.has = function(buf)
    return attachments[buf] ~= nil
  end

  watcher.refresh = function()
    for buf in pairs(attachments) do
      args.changed(buf)
    end
  end

  watcher.retry = function()
    for _, path in pairs(attachments) do
      start(path)
    end
  end

  ---@param buf integer
  ---@param path string
  watcher.update = function(buf, path)
    local previous = attachments[buf]
    if previous == path then
      if path ~= "" then
        start(path)
      end
      return
    end
    attachments[buf] = nil
    if previous then
      close(previous)
    end
    if path ~= "" then
      attachments[buf] = path
      start(path)
    end
  end

  return watcher
end

return M
