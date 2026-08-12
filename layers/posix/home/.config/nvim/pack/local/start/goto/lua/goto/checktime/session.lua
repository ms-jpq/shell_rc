local poll = require "goto.checktime.poller"

local M = {}

local SESSION = "__checktime_session__"
local epoch = 0

---@class ChecktimeRewrite
---@field before integer
---@field after? integer

---@class ChecktimePostWriteCheckpoint
---@field changedtick integer
---@field text string

---@class ChecktimeSession
---@field buf integer
---@field epoch integer
---@field path string
---@field changedtick integer
---@field interval integer
---@field poller? ChecktimePoller
---@field retry? boolean
---@field reading? integer
---@field read_token integer
---@field insert_base? string
---@field reloading? boolean
---@field rewrite? ChecktimeRewrite
---@field writing? boolean
---@field written? string
---@field checkpoint? ChecktimePostWriteCheckpoint
---@field facts? ChecktimeFacts
---@field pending? boolean

---@class ChecktimeWatchConfig
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

---@param buf integer
---@return ChecktimeSession?
M.current = function(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.b[buf][SESSION] or nil
end

---@param session ChecktimeSession
---@return boolean
M.valid = function(session)
  local current = M.current(session.buf)
  return current ~= nil and current.epoch == session.epoch
end

---@param buf integer
---@param path string
---@return ChecktimeSession
M.attach = function(buf, path)
  epoch = epoch + 1
  local session = {
    buf = buf,
    epoch = epoch,
    path = path,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    interval = 0,
    read_token = 0,
  }
  vim.b[buf][SESSION] = session
  return session
end

---@param session ChecktimeSession
M.put = function(session)
  if M.valid(session) then
    vim.b[session.buf][SESSION] = session
  end
end

---@param buf integer
---@return ChecktimeSession?
M.detach = function(buf)
  local session = M.current(buf)
  if session then
    if session.poller then
      session.poller.close()
    end
    vim.b[buf][SESSION] = nil
  end
  return session
end

---@param spec ChecktimeWatchConfig
---@return ChecktimeWatcher
M.start_watch = function(spec)
  ---@diagnostic disable-next-line: missing-fields
  local watch = {} ---@type ChecktimeWatcher

  ---@param buf integer
  ---@return integer
  local interval = function(buf)
    return #vim.fn.win_findbuf(buf) > 0 and spec.visible_interval or spec.hidden_interval
  end

  ---@param current ChecktimeSession
  local start = function(current)
    if current.poller then
      current.poller.close()
    end
    current.interval = interval(current.buf)
    current.poller = poll.start(current.path, function(version)
      if M.valid(current) then
        spec.changed(current.buf, version)
      end
    end, current.interval)
    current.retry = current.poller == nil
    M.put(current)
  end

  ---@param buf integer
  watch.detach = function(buf)
    M.detach(buf)
  end

  ---@param buf integer
  ---@param path string
  ---@param refresh? boolean
  ---@return boolean
  watch.attach = function(buf, path, refresh)
    local current = M.current(buf)
    if current and not refresh then
      return false
    end
    M.detach(buf)
    current = M.attach(buf, path)
    if path ~= "" then
      start(current)
    end
    return true
  end

  ---@param buf integer
  ---@return boolean
  watch.has = function(buf)
    local current = M.current(buf)
    return current ~= nil and current.poller ~= nil
  end

  ---@param buf integer
  ---@param path string
  watch.update = function(buf, path)
    local current = M.current(buf)
    if current and current.path == path and current.interval == interval(buf) then
      if current.retry then
        start(current)
      end
      return
    end
    watch.attach(buf, path, true)
  end

  ---@param buf integer
  watch.refresh = function(buf)
    local current = M.current(buf)
    if current then
      watch.update(buf, current.path)
    end
  end

  watch.retry = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local current = M.current(buf)
      if current and current.retry then
        start(current)
      end
    end
  end

  return watch
end

---@param buf integer
---@return ChecktimeFacts?
M.facts = function(buf)
  local current = M.current(buf)
  return current and current.facts or nil
end

---@param buf integer
---@param facts ChecktimeFacts
M.put_facts = function(buf, facts)
  local current = M.current(buf)
  if current then
    current.facts = facts
    current.pending = next(facts.events) and true or nil
    M.put(current)
  end
end

---@param buf integer
M.drop_facts = function(buf)
  local current = M.current(buf)
  if current then
    current.facts = nil
    current.pending = nil
    M.put(current)
  end
end

---@return integer[]
M.pending = function()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local current = M.current(buf)
    if current and current.pending then
      table.insert(bufs, buf)
    end
  end
  return bufs
end

---@param buf integer
M.defer = function(buf)
  local current = M.current(buf)
  if current then
    current.pending = nil
    M.put(current)
  end
end

---@param buf integer
---@param changedtick integer
---@return boolean
M.changed = function(buf, changedtick)
  local session = M.current(buf)
  if not session or changedtick <= session.changedtick then
    return false
  end
  session.changedtick = changedtick
  M.put(session)
  return true
end

---@param buf integer
---@return ChecktimeSession?, integer?
M.begin_read = function(buf)
  local session = M.current(buf)
  if not session then
    return nil, nil
  end
  session.read_token = session.read_token + 1
  session.reading = session.read_token
  M.put(session)
  return session, session.read_token
end

---@param session ChecktimeSession
---@param token integer
---@return boolean
M.finish_read = function(session, token)
  local current = M.current(session.buf)
  if not current or current.epoch ~= session.epoch or current.reading ~= token then
    return false
  end
  current.reading = nil
  M.put(current)
  return true
end

---@param buf integer
M.cancel_read = function(buf)
  local session = M.current(buf)
  if session then
    session.read_token = session.read_token + 1
    session.reading = nil
    M.put(session)
  end
end

---@param buf integer
---@return boolean
M.reading = function(buf)
  local session = M.current(buf)
  return session ~= nil and session.reading ~= nil
end

---@param buf integer
---@param text string
M.begin_insert = function(buf, text)
  local session = M.current(buf)
  if session then
    session.insert_base = text
    M.put(session)
  end
end

---@param buf integer
---@return string?
M.insert_base = function(buf)
  local session = M.current(buf)
  return session and session.insert_base or nil
end

---@param buf integer
---@return boolean
M.end_insert = function(buf)
  local session = M.current(buf)
  if not session or not session.insert_base then
    return false
  end
  session.insert_base = nil
  M.put(session)
  return true
end

---@param buf integer
---@return boolean
M.reloading = function(buf)
  local current = M.current(buf)
  return current ~= nil and current.reloading == true
end

---@param buf integer
---@param fn fun()
---@return boolean
M.reload = function(buf, fn)
  local current = M.current(buf)
  if not current then
    return false
  end
  current.reloading = true
  M.put(current)
  local ok = pcall(fn)
  current = M.current(buf)
  if current then
    current.reloading = nil
    M.put(current)
  end
  return ok
end

---@param buf integer
---@param fn fun(): boolean
---@return boolean
M.rewrite = function(buf, fn)
  local current = M.current(buf)
  if not current then
    return false
  end
  local rewrite = { before = vim.api.nvim_buf_get_changedtick(buf) } ---@type ChecktimeRewrite
  current.rewrite = rewrite
  M.put(current)
  local ok, rewritten = xpcall(fn, debug.traceback)
  if not ok then
    current = M.current(buf)
    if current then
      current.rewrite = nil
      M.put(current)
    end
    error(rewritten, 0)
  end
  current = M.current(buf)
  if current then
    rewrite.after = vim.api.nvim_buf_get_changedtick(buf)
    current.rewrite = rewrite
    M.put(current)
  end
  return rewritten
end

---@param buf integer
---@return ChecktimeRewrite?
M.take_rewrite = function(buf)
  local current = M.current(buf)
  if not current then
    return nil
  end
  local rewrite = current.rewrite
  current.rewrite = nil
  M.put(current)
  return rewrite
end

---@param buf integer
---@param changedtick integer
---@return boolean
M.is_echo = function(buf, changedtick)
  local current = M.current(buf)
  local rewrite = current and current.rewrite
  return rewrite ~= nil and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after)
end

---@param buf integer
M.clear_rewrite = function(buf)
  local current = M.current(buf)
  if current then
    current.rewrite = nil
    M.put(current)
  end
end

---@param buf integer
---@param value boolean
M.write = function(buf, value)
  local current = M.current(buf)
  if current then
    current.writing = value or nil
    M.put(current)
  end
end

---@param buf integer
---@return boolean
M.writing = function(buf)
  local current = M.current(buf)
  return current ~= nil and current.writing == true
end

---@param buf integer
---@param text string
M.remember_written = function(buf, text)
  local current = M.current(buf)
  if current then
    current.written = text
    M.put(current)
  end
end

---@param buf integer
---@return string?
M.take_written = function(buf)
  local current = M.current(buf)
  if not current then
    return nil
  end
  local written = current.written
  current.written = nil
  M.put(current)
  return written
end

---@param buf integer
---@param checkpoint ChecktimePostWriteCheckpoint
M.remember_checkpoint = function(buf, checkpoint)
  local current = M.current(buf)
  if current then
    current.checkpoint = checkpoint
    M.put(current)
  end
end

---@param buf integer
---@return ChecktimePostWriteCheckpoint?
M.take_checkpoint = function(buf)
  local current = M.current(buf)
  if not current then
    return nil
  end
  local checkpoint = current.checkpoint
  current.checkpoint = nil
  M.put(current)
  return checkpoint
end

return M
