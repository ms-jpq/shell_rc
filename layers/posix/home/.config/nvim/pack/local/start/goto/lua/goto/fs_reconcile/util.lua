local async = require "goto.async"
local lib = require "goto.lib"

local M = {}
local MAX_BYTES = 2 * 1024 * 1024

---@class FsReconcilePoller
---@field path string
---@field close fun()

---@class FsReconcileSnapshot: FsReconcileBuffer
---@field changedtick integer
---@field fileencoding string
---@field encoding string

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
  local linefeed = lib.buf_linefeed(buf)
  local text = table.concat(lines, linefeed)
  return {
    linefeed = linefeed,
    text = endofline and text .. linefeed or text,
    endofline = endofline,
    final_empty = lines[#lines] == "",
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    fileencoding = vim.bo[buf].fileencoding,
    encoding = vim.o.encoding,
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
      path = path,
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

---@param snapshot FsReconcileSnapshot
---@param text string
---@return string?
local decode = function(snapshot, text)
  if snapshot.fileencoding ~= "" and snapshot.fileencoding ~= snapshot.encoding then
    text = vim.fn.iconv(text, snapshot.fileencoding, snapshot.encoding)
  end
  local remainder = string.gsub(text, snapshot.linefeed, "")
  return not string.find(remainder, "[\r\n]") and text or nil
end

---@param snapshot FsReconcileSnapshot
---@param text string
---@return string
local merge_text = function(snapshot, text)
  if snapshot.final_empty and not snapshot.endofline then
    return text .. snapshot.linefeed
  elseif snapshot.endofline and not vim.endswith(text, snapshot.linefeed) then
    return text .. snapshot.linefeed
  end
  return text
end

---@param snapshot FsReconcileSnapshot
---@param text string
---@return string
M.buffer_text = function(snapshot, text)
  local ending = vim.endswith(text, snapshot.linefeed)
  if text == snapshot.linefeed then
    return ""
  elseif snapshot.endofline then
    return ending and text or text .. snapshot.linefeed
  elseif ending then
    return string.sub(text, 1, -#snapshot.linefeed - 1)
  end
  return text
end

---@param path string
---@param snapshot FsReconcileSnapshot
---@return FsReconcileBase?
M.read_file = function(path, snapshot)
  local before = vim.uv.fs_stat(path)
  if not before then
    return { text = "" }
  elseif before.size > MAX_BYTES then
    return
  end
  local ok, text = pcall(vim.fn.readblob, path)
  if not ok or type(text) ~= "string" then
    return
  end
  text = decode(snapshot, text)
  local after = vim.uv.fs_stat(path)
  if not text or not M.same_version(before, after) then
    return
  end
  return { text = M.buffer_text(snapshot, merge_text(snapshot, text)), version = before }
end

return M
