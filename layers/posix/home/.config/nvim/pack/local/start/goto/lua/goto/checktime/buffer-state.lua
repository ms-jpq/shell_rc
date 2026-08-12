local M = {}

do
  local REGISTRATION = "__checktime_registration__"

  ---@class ChecktimeBufferRegistration
  ---@field changedtick integer
  ---@field generation integer
  ---@field interval integer
  ---@field path string
  ---@field poller? ChecktimePoller
  ---@field retry? boolean

  ---@param buf integer
  ---@return ChecktimeBufferRegistration?
  M.registration = function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.b[buf][REGISTRATION] or nil
  end

  ---@param buf integer
  ---@param registration ChecktimeBufferRegistration
  M.put_registration = function(buf, registration)
    vim.b[buf][REGISTRATION] = registration
  end

  ---@param buf integer
  M.clear_registration = function(buf)
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf][REGISTRATION] = nil
    end
  end

  ---@param buf integer
  ---@param changedtick integer
  ---@return boolean
  M.changed = function(buf, changedtick)
    local registration = M.registration(buf)
    if not registration or changedtick <= registration.changedtick then
      return false
    end
    registration.changedtick = changedtick
    M.put_registration(buf, registration)
    return true
  end
end

do
  local RELOADING = "__checktime_reloading__"

  ---@param buf integer
  ---@return boolean
  M.reloading = function(buf)
    return vim.b[buf][RELOADING] == true
  end

  ---@param buf integer
  ---@param fn fun()
  ---@return boolean
  M.reload = function(buf, fn)
    vim.b[buf][RELOADING] = true
    local ok = pcall(fn)
    vim.b[buf][RELOADING] = nil
    return ok
  end
end

do
  local REWRITE = "__checktime_rewrite__"

  ---@class ChecktimeRewrite
  ---@field before integer
  ---@field after? integer

  ---@param buf integer
  ---@param fn fun(): boolean
  ---@return boolean
  M.rewrite = function(buf, fn)
    local rewrite = { before = vim.api.nvim_buf_get_changedtick(buf) } ---@type ChecktimeRewrite
    vim.b[buf][REWRITE] = rewrite
    local ok, rewritten = xpcall(fn, debug.traceback)
    if not ok then
      vim.b[buf][REWRITE] = nil
      error(rewritten, 0)
    end
    rewrite.after = vim.api.nvim_buf_get_changedtick(buf)
    vim.b[buf][REWRITE] = rewrite
    return rewritten
  end

  ---@param buf integer
  ---@return ChecktimeRewrite?
  M.take_rewrite = function(buf)
    local rewrite = vim.b[buf][REWRITE]
    vim.b[buf][REWRITE] = nil
    return rewrite
  end

  ---@param buf integer
  ---@param changedtick integer
  ---@return boolean
  M.is_echo = function(buf, changedtick)
    local rewrite = vim.b[buf][REWRITE]
    return rewrite ~= nil and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after)
  end

  ---@param buf integer
  M.clear_rewrite = function(buf)
    vim.b[buf][REWRITE] = nil
  end
end

do
  local WRITING = "__checktime_writing__"

  ---@param buf integer
  ---@param value boolean
  M.write = function(buf, value)
    vim.b[buf][WRITING] = value or nil
  end

  ---@param buf integer
  ---@return boolean
  M.writing = function(buf)
    return vim.b[buf][WRITING] == true
  end
end

do
  local WRITTEN = "__checktime_written__"

  ---@param buf integer
  ---@param text string
  M.remember_written = function(buf, text)
    vim.b[buf][WRITTEN] = text
  end

  ---@param buf integer
  ---@return string?
  M.take_written = function(buf)
    local written = vim.b[buf][WRITTEN]
    vim.b[buf][WRITTEN] = nil
    return written
  end
end

do
  local CHECKPOINT = "__checktime_checkpoint__"

  ---@class ChecktimePostWriteCheckpoint
  ---@field changedtick integer
  ---@field text string

  ---@param buf integer
  ---@param checkpoint ChecktimePostWriteCheckpoint
  M.remember_checkpoint = function(buf, checkpoint)
    vim.b[buf][CHECKPOINT] = checkpoint
  end

  ---@param buf integer
  ---@return ChecktimePostWriteCheckpoint?
  M.take_checkpoint = function(buf)
    local checkpoint = vim.b[buf][CHECKPOINT]
    vim.b[buf][CHECKPOINT] = nil
    return checkpoint
  end
end

return M
