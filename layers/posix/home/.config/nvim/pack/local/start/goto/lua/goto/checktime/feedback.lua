local M = {}

---@class ChecktimeRewrite
---@field before integer
---@field after? integer

local RELOADING = "__checktime_reloading__"
local REWRITE = "__checktime_rewrite__"
local WRITING = "__checktime_writing__"

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

---@param buf integer
---@param fn fun()
M.rewrite = function(buf, fn)
  local rewrite = { before = vim.api.nvim_buf_get_changedtick(buf) } ---@type ChecktimeRewrite
  vim.b[buf][REWRITE] = rewrite
  fn()
  rewrite.after = vim.api.nvim_buf_get_changedtick(buf)
  vim.b[buf][REWRITE] = rewrite
end

---@param buf integer
---@return ChecktimeRewrite?
M.take_rewrite = function(buf)
  local rewrite = vim.b[buf][REWRITE]
  vim.b[buf][REWRITE] = nil
  return rewrite
end

---@param buf integer
M.clear_rewrite = function(buf)
  vim.b[buf][REWRITE] = nil
end

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

return M
