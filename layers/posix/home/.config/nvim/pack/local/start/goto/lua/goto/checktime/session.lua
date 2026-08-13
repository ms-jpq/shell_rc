local poll = require "goto.checktime.poller"

local M = {}

local SESSION = "__checktime_session__"
local epoch = 0

---@class ChecktimeRewrite
---@field before integer
---@field after? integer

---@class ChecktimeWatchBinding
---@field path string
---@field epoch integer
---@field interval integer
---@field enabled boolean
---@field poller? ChecktimePoller
---@field retry? boolean

---@class ChecktimeSession
---@field buf integer
---@field epoch integer
---@field changedtick integer
---@field watch ChecktimeWatchBinding
---@field reading? integer
---@field read_token integer
---@field insert_base? string
---@field reloading? boolean
---@field rewrite? ChecktimeRewrite
---@field writing? boolean
---@field written? string
---@field mailbox? ChecktimeMailboxFacts

---@class ChecktimeWatchConfig
---@field changed fun(buf: integer, version?: uv.fs_stat.result)
---@field visible_interval integer
---@field hidden_interval integer

---@class ChecktimeWatcher
---@field attach fun(buf: integer, path: string, refresh?: boolean, enabled?: boolean): boolean
---@field detach fun(buf: integer)
---@field has fun(buf: integer): boolean
---@field refresh fun(buf: integer)
---@field retry fun()
---@field update fun(buf: integer, path: string, enabled: boolean): boolean rebase

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
  M.detach(buf)
  epoch = epoch + 1
  local session = {
    buf = buf,
    epoch = epoch,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    watch = { path = path, epoch = 0, interval = 0, enabled = false },
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
    if session.watch.poller then
      session.watch.poller.close()
    end
    vim.b[buf][SESSION] = nil
  end
  return session
end

---@param spec ChecktimeWatchConfig
---@return ChecktimeWatcher
M.start_watch = function(spec)
  ---@diagnostic disable-next-line: missing-fields
  local w = {} ---@type ChecktimeWatcher

  ---@param buf integer
  ---@return integer
  local interval = function(buf)
    return #vim.fn.win_findbuf(buf) > 0 and spec.visible_interval or spec.hidden_interval
  end

  ---@param current ChecktimeSession
  local start = function(current)
    local binding = current.watch
    if binding.poller then
      binding.poller.close()
    end
    binding.epoch = binding.epoch + 1
    binding.interval = interval(current.buf)
    local epoch = binding.epoch
    binding.poller = poll.start(binding.path, function(version)
      local active = M.current(current.buf)
      if active and active.epoch == current.epoch and active.watch.epoch == epoch then
        spec.changed(current.buf, version)
      end
    end, binding.interval)
    binding.retry = binding.poller == nil
    M.put(current)
  end

  ---@param current ChecktimeSession
  ---@param path string
  ---@param enabled boolean
  ---@return boolean rebase
  local bind = function(current, path, enabled)
    local binding = current.watch
    local path_changed = binding.path ~= path
    local rebase = enabled and (path_changed or not binding.enabled)
    if not enabled then
      if binding.poller then
        binding.poller.close()
      end
      binding.epoch = binding.epoch + 1
      binding.poller = nil
      binding.retry = nil
      binding.interval = interval(current.buf)
      binding.enabled = false
      M.put(current)
      return false
    end
    if not path_changed and binding.enabled and binding.interval == interval(current.buf) then
      if binding.retry then
        start(current)
      end
      return false
    end
    binding.path = path
    binding.enabled = true
    start(current)
    return rebase
  end

  ---@param buf integer
  w.detach = function(buf)
    M.detach(buf)
  end

  ---@param buf integer
  ---@param path string
  ---@param refresh? boolean
  ---@return boolean
  w.attach = function(buf, path, refresh, enabled)
    enabled = enabled == nil and path ~= "" or enabled
    local current = M.current(buf)
    if current and not refresh then
      return false
    end
    if current then
      bind(current, path, enabled)
      return true
    end
    current = M.attach(buf, path)
    bind(current, path, enabled)
    return true
  end

  ---@param buf integer
  ---@return boolean
  w.has = function(buf)
    local current = M.current(buf)
    return current ~= nil and current.watch.poller ~= nil
  end

  ---@param buf integer
  ---@param path string
  w.update = function(buf, path, enabled)
    local current = M.current(buf)
    if not current then
      return false
    end
    return bind(current, path, enabled)
  end

  ---@param buf integer
  w.refresh = function(buf)
    local current = M.current(buf)
    if current then
      w.update(buf, current.watch.path, current.watch.enabled)
    end
  end

  w.retry = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local current = M.current(buf)
      if current and current.watch.enabled and current.watch.retry then
        start(current)
      end
    end
  end

  return w
end

---@param buf integer
---@return ChecktimeMailboxFacts?
M.mailbox = function(buf)
  local current = M.current(buf)
  return current and current.mailbox or nil
end

---@param buf integer
---@param mailbox ChecktimeMailboxFacts
M.put_mailbox = function(buf, mailbox)
  local current = M.current(buf)
  if current then
    current.mailbox = mailbox
    M.put(current)
  end
end

---@param buf integer
M.drop_mailbox = function(buf)
  local current = M.current(buf)
  if current then
    current.mailbox = nil
    M.put(current)
  end
end

---@return integer[]
M.mailbox_buffers = function()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local current = M.current(buf)
    if current and current.mailbox and next(current.mailbox.events) then
      table.insert(bufs, buf)
    end
  end
  return bufs
end

---@return integer[]
M.buffers = function()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if M.current(buf) then
      table.insert(bufs, buf)
    end
  end
  return bufs
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

return M
