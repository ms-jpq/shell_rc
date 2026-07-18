local lib = require "go.lib"
local poll = require "go.checktime.poll"
local snapshot = require "go.checktime.snapshot"

local M = {}

M.start = function()
  local files = poll.new()

  local watcher = { dirty_all = files.dirty_all }

  local remember = function(buf, lines)
    vim.b[buf][snapshot.BASE] = lines or vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  end

  local watch = function(buf)
    files.unwatch(buf)

    if not vim.bo[buf].modifiable then
      return
    end

    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
      return
    end
    files.watch(buf, name)
  end

  watcher.take = function()
    local changes = {}
    for buf in pairs(files.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable then
        changes[buf] = true
      else
        files.unwatch(buf)
      end
    end
    return changes
  end

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      files.unwatch(args.buf)
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
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      watch(buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      remember(args.buf)
    end,
  })

  lib.vim_enter(function()
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
