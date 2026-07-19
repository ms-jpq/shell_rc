local lib = require "go.lib"
local poll = require "go.checktime.poll"
local snapshot = require "go.checktime.snapshot"

local M = {}

M.start = function()
  local files = poll.new()
  local retry = {}

  local watcher = { dirty_all = files.dirty_all }

  local remember = function(buf, lines)
    vim.b[buf][snapshot.BASE] = lines or vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  end

  local watch = function(buf)
    retry[buf] = nil
    files.unwatch(buf)

    if not vim.bo[buf].modifiable then
      return
    end

    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
      return
    end
    if not files.watch(buf, name) then
      retry[buf] = true
    end
  end

  watcher.take = function()
    local changes = files.take()
    for buf in pairs(retry) do
      changes[buf] = true
    end
    for buf in pairs(changes) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable then
        if retry[buf] then
          watch(buf)
        end
      else
        retry[buf] = nil
        files.unwatch(buf)
      end
    end
    return changes
  end

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      retry[args.buf] = nil
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
