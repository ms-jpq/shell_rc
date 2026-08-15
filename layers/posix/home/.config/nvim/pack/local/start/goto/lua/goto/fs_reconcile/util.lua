local async = require "goto.async"
local lib = require "goto.lib"

local M = {}
local MAX_BYTES = 2 * 1024 * 1024
local UTF8_BOM = "\239\187\191"

---@class FsReconcileReadStates
---@field OPAQUE "opaque"
---@field UNSTABLE "unstable"

---@type FsReconcileReadStates
M.READ = {
  OPAQUE = "opaque",
  UNSTABLE = "unstable",
}

---@param left? uv.fs_stat.result
---@param right? uv.fs_stat.result
---@return boolean
M.same_file = function(left, right)
  return left ~= nil and right ~= nil and left.dev == right.dev and left.ino == right.ino
end

---@class FsReconcileBuffer
---@field text string

---@class FsReconcileBase
---@field text string
---@field version? uv.fs_stat.result

---@class FsReconcilePoller
---@field close fun()

---@class FsReconcileSnapshot: FsReconcileBuffer
---@field changedtick integer

---@param left? uv.fs_stat.result
---@param right? uv.fs_stat.result
---@return boolean
M.same_version = function(left, right)
  return left ~= nil
    and right ~= nil
    and left.dev == right.dev
    and left.ino == right.ino
    and left.size == right.size
    and left.mtime.sec == right.mtime.sec
    and left.mtime.nsec == right.mtime.nsec
    and left.ctime.sec == right.ctime.sec
    and left.ctime.nsec == right.ctime.nsec
end

---@param left FsReconcileBase
---@param right FsReconcileBase
---@return boolean
M.same_base = function(left, right)
  if not left.version then
    return not right.version
  elseif right.version then
    return M.same_version(left.version, right.version)
  end
  return false
end

---@param path string
---@param base FsReconcileBase
---@return boolean
M.unchanged = function(path, base)
  local version = vim.uv.fs_stat(path)
  if not base.version then
    return not version
  elseif version then
    return M.same_version(base.version, version)
  end
  return false
end

---@param buf integer
---@return FsReconcileSnapshot
M.buffer = function(buf)
  local endofline = vim.bo[buf].endofline
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local text = table.concat(lines, lib.LF)
  return {
    text = endofline and text .. lib.LF or text,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
  }
end

---@param path string
---@param interval integer
---@param wake fun()
---@return FsReconcilePoller?
M.poller = function(path, interval, wake)
  local poll = vim.uv.new_fs_poll()
  local changed = async(function()
    async.scheduled()
    wake()
  end)
  if not poll then
    return
  elseif poll:start(path, interval, changed) then
    local closed = false
    return {
      close = function()
        if not closed then
          closed = true
          poll:stop()
          poll:close()
        end
      end,
    }
  end
  poll:close()
end

---@param buf integer
---@param text string
---@return string?
local decode = function(buf, text)
  local fileencoding = vim.bo[buf].fileencoding
  if fileencoding ~= "" and fileencoding ~= vim.o.encoding then
    text = vim.fn.iconv(text, fileencoding, vim.o.encoding)
  end
  if vim.startswith(text, UTF8_BOM) then
    text = string.sub(text, #UTF8_BOM + 1)
  end
  return (string.gsub(text, "\r?\n", lib.LF))
end

---@param buf integer
---@param path string
---@return FsReconcileBase?
---@return "opaque"|"unstable"?
M.read_file = function(buf, path)
  local before = vim.uv.fs_stat(path)
  if not before then
    return { text = "" }
  elseif before.size > MAX_BYTES then
    return nil, M.READ.OPAQUE
  end
  local ok, text = pcall(vim.fn.readblob, path)
  if not ok or type(text) ~= "string" then
    return nil, M.READ.UNSTABLE
  end
  text = decode(buf, assert(text))
  local after = vim.uv.fs_stat(path)
  if not text then
    return nil, M.READ.OPAQUE
  elseif not M.same_version(before, after) then
    return nil, M.READ.UNSTABLE
  end
  return { text = text, version = after }
end

return M
