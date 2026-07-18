local lib = require "go.lib"
local snapshot = require "go.checktime.snapshot"

local M = {}

local uv_watcher = {}
uv_watcher.new = function(directory, changed)
  local watcher = { directory = directory }

  local handle = vim.uv.new_fs_event()
  if not handle then
    return nil
  end

  local bufs = {}
  local ok = handle:start(directory, {}, function(_, filename)
    for buf, target in pairs(bufs) do
      if not filename or vim.fs.basename(filename) == target then
        changed(buf)
      end
    end
  end)
  if not ok then
    handle:close()
    return nil
  end

  watcher.add = function(buf, name)
    bufs[buf] = name
  end

  watcher.remove = function(buf)
    bufs[buf] = nil
    if next(bufs) then
      return false
    end

    handle:stop()
    handle:close()
    return true
  end

  return watcher
end

M.start = function()
  local watcher = {}

  local dirty, polling = {}, {}
  local dir_watchers = {}

  local remember = function(buf, lines)
    vim.b[buf][snapshot.BASE] = lines or vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  end

  local unwatch = function(buf)
    dirty[buf] = nil
    polling[buf] = nil

    local dir_watcher = dir_watchers[buf]
    dir_watchers[buf] = nil
    if not dir_watcher then
      return
    end

    if dir_watcher.remove(buf) then
      dir_watchers[dir_watcher.directory] = nil
    end
  end

  local start_uv_watcher = function(directory)
    local dir_watcher = dir_watchers[directory]
    if dir_watcher then
      return dir_watcher
    end

    dir_watcher = uv_watcher.new(directory, function(buf)
      dirty[buf] = true
    end)
    if not dir_watcher then
      return nil
    end

    dir_watchers[directory] = dir_watcher
    return dir_watcher
  end

  local watch = function(buf)
    unwatch(buf)

    if not vim.bo[buf].modifiable then
      return
    end

    local name = vim.api.nvim_buf_get_name(buf)
    local directory = name ~= "" and vim.fs.dirname(name)
    if not directory then
      return
    end
    remember(buf)

    local dir_watcher = start_uv_watcher(directory)
    if not dir_watcher then
      polling[buf] = true
      return
    end

    dir_watcher.add(buf, vim.fs.basename(name))
    dir_watchers[buf] = dir_watcher
  end

  local watch_loaded = function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        watch(buf)
      end
    end
  end

  watcher.take = function()
    for buf in pairs(polling) do
      dirty[buf] = true
    end

    for buf in pairs(dirty) do
      if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].modifiable then
        unwatch(buf)
      end
    end

    local changes = dirty
    dirty = {}
    return changes
  end

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      unwatch(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufFilePost" }, {
    group = lib.group,
    callback = function(args)
      watch(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = "modifiable",
    callback = function(args)
      watch(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      remember(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "VimEnter" }, {
    group = lib.group,
    once = true,
    callback = watch_loaded,
  })

  return watcher
end

return M
