local autocmd = require "goto.autocmd"
local lib = require "goto.lib"
local poll = require "goto.checktime.poll"
local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeWatch
---@field dirty fun(kind: ChecktimeChange, buf?: integer)
---@field remember fun(buf: integer, base?: string, version?: uv.fs_stat.result)
---@field take fun(): table<integer, ChecktimeUpdate>

---@return ChecktimeWatch
M.start = function()
  local files = poll.new()

  ---@diagnostic disable-next-line: missing-fields
  local watcher = {} ---@type ChecktimeWatch
  watcher.dirty = files.dirty
  watcher.remember = files.remember
  watcher.take = files.take

  ---@param buf integer
  local remember = function(buf)
    local state, version, base = snapshot.read(buf)
    if state == snapshot.STATES.RECONCILE then
      files.remember(buf, base, version)
    elseif state == snapshot.STATES.RETRY then
      files.dirty(poll.REMOTE, buf)
    else
      files.remember(buf)
    end
  end

  ---@param buf integer
  local watch = function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local path = vim.bo[buf].modifiable and name ~= "" and name or nil
    files.watch(buf, path)
  end

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      files.forget(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost", "BufFilePost" }, {
    group = lib.group,
    callback = function(args)
      remember(args.buf)
      watch(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = "modifiable",
    callback = function(args)
      local buf = args.buf
      watch(buf)
      if vim.bo[buf].modifiable then
        files.dirty(poll.REMOTE, buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = lib.group,
    callback = function(args)
      files.dirty(poll.LOCAL, args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      remember(args.buf)
    end,
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        remember(buf)
        watch(buf)
      end
    end
  end)

  return watcher
end

return M
