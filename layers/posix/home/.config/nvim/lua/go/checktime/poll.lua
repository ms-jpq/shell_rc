local lib = require "go.lib"

local M = {}

M.DIRTY = "__checktime_dirty__"

local d_watcher = {}
d_watcher.new = function(path, changed)
  local watcher = { path = path }

  local handle = vim.uv.new_fs_event()
  if not handle then
    return nil
  end

  local ok = handle:start(path, {}, function(_, filename)
    changed(filename)
  end)
  if not ok then
    handle:close()
    return nil
  end

  watcher.close = function()
    handle:stop()
    handle:close()
  end

  return watcher
end

local f_watcher = {}
f_watcher.new = function(path, changed)
  local watcher = { path = path }

  local handle = vim.uv.new_fs_poll()
  if not handle then
    return nil
  end

  local ok = handle:start(path, 99, changed)
  if not ok then
    handle:close()
    return nil
  end

  watcher.close = function()
    handle:stop()
    handle:close()
  end

  return watcher
end

M.new = function()
  local w = {}
  local entries, watchers = {}, {}

  local mark = function(buf, value)
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf][M.DIRTY] = value
    end
  end

  w.unwatch = function(buf)
    mark(buf, nil)
    local watcher = watchers[buf]
    watchers[buf] = nil
    if not watcher then
      return
    end

    watcher.bufs[buf] = nil
    if not next(watcher.bufs) then
      watcher.close()
      entries[watcher.path] = nil
    end
  end

  local start_watcher = function(path)
    local directory = vim.fs.dirname(path)
    local directory_key = directory .. lib.os.sep
    local watcher = entries[directory_key]

    if watcher == nil then
      local bufs = {}
      local changed = vim.schedule_wrap(function(filename)
        for buf, p in pairs(bufs) do
          if not filename or vim.fs.basename(p) == filename then
            mark(buf, true)
          end
        end
      end)
      watcher = d_watcher.new(directory_key, changed)
      if watcher then
        watcher.bufs = bufs
        entries[directory_key] = watcher
      else
        entries[directory_key] = false
      end
    end

    if watcher then
      return watcher
    end

    watcher = entries[path]
    if watcher == nil then
      local bufs = {}
      local changed = vim.schedule_wrap(function(filename)
        for buf, p in pairs(bufs) do
          if not filename or vim.fs.basename(p) == filename then
            mark(buf, true)
          end
        end
      end)
      watcher = f_watcher.new(path, changed)
      if watcher then
        watcher.bufs = bufs
        entries[path] = watcher
      end
    end

    return watcher
  end

  w.watch = function(buf, path)
    w.unwatch(buf)

    local watcher = start_watcher(path)
    if not watcher then
      return false
    end

    watcher.bufs[buf] = path
    watchers[buf] = watcher
    return true
  end

  w.dirty_all = function()
    for buf in pairs(watchers) do
      mark(buf, true)
    end
  end

  w.take = function()
    local changes = {}
    for buf in pairs(watchers) do
      if vim.api.nvim_buf_is_valid(buf) and vim.b[buf][M.DIRTY] then
        mark(buf, nil)
        changes[buf] = true
      end
    end
    return changes
  end

  return w
end

return M
