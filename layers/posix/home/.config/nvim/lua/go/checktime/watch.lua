local autocmd = require "go.autocmd"
local lib = require "go.lib"
local poll = require "go.checktime.poll"
local snapshot = require "go.checktime.snapshot"

local M = {}

---@class ChecktimeWatch
---@field dirty fun(kind: ChecktimeChange, buf?: integer)
---@field remember fun(buf: integer, base: string)
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
  ---@param base? string
  local watch = function(buf, base)
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].modifiable and name ~= "" then
      files.watch(buf, name, base)
    else
      files.watch(buf, nil, base)
    end
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
      watch(args.buf, snapshot.current(args.buf).text)
    end,
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = "modifiable",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      watch(buf)
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
      files.remember(args.buf, snapshot.current(args.buf).text)
    end,
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        watch(buf, snapshot.current(buf).text)
      end
    end
  end)

  return watcher
end

return M
