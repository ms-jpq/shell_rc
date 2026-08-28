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
M.same_identity = function(left, right)
  return left ~= nil and right ~= nil and left.dev == right.dev and left.ino == right.ino
end

---@class FsReconcileBuffer
---@field text string
---@field endofline boolean

---@class FsReconcileBase: FsReconcileBuffer
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

---@param left? uv.fs_stat.result
---@param right? uv.fs_stat.result
---@return boolean
M.same_observation = function(left, right)
  return (left == nil and right == nil) or M.same_version(left, right)
end

---@param left FsReconcileBuffer
---@param right FsReconcileBuffer
---@return boolean
M.same_buffer = function(left, right)
  return left.text == right.text and left.endofline == right.endofline
end

---@param buf integer
---@return FsReconcileBase
M.empty = function(buf)
  return { text = "", endofline = vim.bo[buf].endofline }
end

---@param text string
---@return FsReconcileBuffer
M.from_text = function(text)
  local endofline = vim.endswith(text, lib.LF)
  if endofline then
    text = string.sub(text, 1, -#lib.LF - 1)
  end
  return { text = text, endofline = endofline }
end

---@param base FsReconcileBuffer
---@param local_value FsReconcileBuffer
---@param remote FsReconcileBuffer
---@return boolean
M.merge_endofline = function(base, local_value, remote)
  if local_value.endofline == remote.endofline then
    return local_value.endofline
  elseif local_value.endofline == base.endofline then
    return remote.endofline
  end
  return local_value.endofline
end

---@param snapshot FsReconcileBuffer
---@param output string
---@return FsReconcileBuffer
M.format_output = function(snapshot, output)
  local target = M.from_text(output)
  target.endofline = snapshot.endofline
  return target
end

---@param path string
---@param base FsReconcileBase
---@return boolean
M.unchanged = function(path, base)
  return M.same_observation(base.version, vim.uv.fs_stat(path))
end

---@param buf integer
---@return FsReconcileSnapshot
M.buffer = function(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  return {
    text = table.concat(lines, lib.LF),
    endofline = vim.bo[buf].endofline,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
  }
end

---@param path string
---@param interval integer
---@param wake fun()
---@return FsReconcilePoller?
M.poller = function(path, interval, wake)
  local poll = vim.uv.new_fs_poll()
  if not poll then
    return
  elseif poll:start(path, interval, vim.schedule_wrap(wake)) then
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
    local converted = vim.fn.iconv(text, fileencoding, vim.o.encoding)
    if text ~= "" and converted == "" then
      return
    end
    text = converted
  end
  if vim.startswith(text, UTF8_BOM) then
    text = string.sub(text, #UTF8_BOM + 1)
  end
  text = string.gsub(string.gsub(text, "\r\n", lib.LF), "\r", lib.LF)
  return text
end

---@param buf integer
---@param path string
---@return FsReconcileBase?
---@return "opaque"|"unstable"?
M.read_file = function(buf, path)
  local before, _, code = vim.uv.fs_stat(path)
  if not before then
    if code == "ENOENT" then
      return M.empty(buf)
    end
    return nil, M.READ.UNSTABLE
  elseif before.type ~= "file" or before.size > MAX_BYTES then
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
  local base = M.from_text(text)
  return { text = base.text, endofline = base.endofline, version = after }
end

return M
