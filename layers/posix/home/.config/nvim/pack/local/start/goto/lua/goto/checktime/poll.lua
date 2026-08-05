local M = {}

---@alias ChecktimeChange "remote"|"local"
---@alias ChecktimeDirty table<ChecktimeChange, true>

---@class ChecktimePoller
---@field path string
---@field bufs table<integer, true>
---@field close fun()

---@class ChecktimeTracked
---@field base? string
---@field version? uv.fs_stat.result
---@field dirty? ChecktimeDirty
---@field retry? string
---@field watcher? ChecktimePoller

---@class ChecktimeUpdate
---@field base? string
---@field version? uv.fs_stat.result
---@field dirty ChecktimeDirty

---@class ChecktimePoll
---@field remember fun(buf: integer, base?: string, version?: uv.fs_stat.result)
---@field forget fun(buf: integer)
---@field watch fun(buf: integer, path?: string)
---@field dirty fun(kind: ChecktimeChange, buf?: integer)
---@field take fun(): table<integer, ChecktimeUpdate>

M.REMOTE, M.LOCAL = "remote", "local"

local poller = {}

---@param path string
---@param bufs table<integer, true>
---@param changed fun()
---@return ChecktimePoller?
poller.new = function(path, bufs, changed)
  local handle = vim.uv.new_fs_poll()
  if not handle then
    return nil
  end

  local ok = handle:start(path, 99, changed)
  if not ok then
    handle:close()
    return nil
  end

  ---@diagnostic disable-next-line: missing-fields
  local p = { path = path, bufs = bufs } ---@type ChecktimePoller
  p.close = function()
    handle:stop()
    handle:close()
  end

  return p
end

---@return ChecktimePoll
M.new = function()
  ---@diagnostic disable-next-line: missing-fields
  local w = {} ---@type ChecktimePoll

  ---@type table<string, ChecktimePoller>
  local entries = {}
  ---@type table<integer, ChecktimeTracked>
  local tracked = {}

  ---@param buf integer
  local clear = function(buf)
    local state = tracked[buf]
    if state then
      state.dirty = nil
    end
  end

  ---@param kind ChecktimeChange
  ---@param buf integer
  local dirty = function(kind, buf)
    local state = tracked[buf] or {}
    tracked[buf] = state
    state.dirty = state.dirty or {}
    state.dirty[kind] = true
  end

  ---@param buf integer
  local detach = function(buf)
    local state = tracked[buf]
    local watcher = state and state.watcher
    if state then
      state.retry = nil
    end
    if not watcher then
      return
    end

    watcher.bufs[buf] = nil
    state.watcher = nil
    if not next(watcher.bufs) then
      watcher.close()
      entries[watcher.path] = nil
    end
  end

  ---@param path string
  ---@return ChecktimePoller?
  local start_watcher = function(path)
    ---@type ChecktimePoller?
    local watcher = entries[path]
    if watcher == nil then
      local bufs = {}
      local changed = vim.schedule_wrap(function()
        for buf in pairs(bufs) do
          dirty(M.REMOTE, buf)
        end
      end)
      watcher = poller.new(path, bufs, changed)
      if watcher then
        entries[path] = watcher
      end
    end

    return watcher
  end

  ---@param buf integer
  ---@param path string
  local attach = function(buf, path)
    local state = tracked[buf] or {}
    tracked[buf] = state
    state.retry = path
    local watcher = start_watcher(path)
    if watcher then
      watcher.bufs[buf] = true
      state.watcher = watcher
      state.retry = nil
    end
  end

  ---@param buf integer
  ---@param base string?
  ---@param version uv.fs_stat.result?
  w.remember = function(buf, base, version)
    local state = tracked[buf]
    if state then
      state.base = base
      state.version = version
    else
      tracked[buf] = { base = base, version = version }
    end
  end

  ---@param buf integer
  w.forget = function(buf)
    detach(buf)
    tracked[buf] = nil
  end

  ---@param buf integer
  ---@param path? string
  w.watch = function(buf, path)
    detach(buf)
    if path then
      attach(buf, path)
    end
  end

  ---@param kind ChecktimeChange
  ---@param buf? integer
  w.dirty = function(kind, buf)
    if buf then
      return dirty(kind, buf)
    end
    for b, state in pairs(tracked) do
      if state.watcher then
        dirty(kind, b)
      end
    end
  end

  ---@return table<integer, ChecktimeUpdate>
  w.take = function()
    local changes = {}
    for buf, state in pairs(tracked) do
      if state.retry and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable then
        attach(buf, state.retry)
        dirty(M.REMOTE, buf)
      end
      if (state.watcher or state.retry) and state.dirty then
        local dirty = state.dirty
        clear(buf)
        changes[buf] = { base = state.base, version = state.version, dirty = dirty }
      end
    end
    return changes
  end

  return w
end

return M
