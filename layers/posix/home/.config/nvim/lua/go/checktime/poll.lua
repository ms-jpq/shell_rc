local lib = require "go.lib"

local M = {}

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
  local dirty, entries, watchers = {}, {}, {}

  w.unwatch = function(buf)
    dirty[buf] = nil
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
      local changed = function(filename)
        for buf, path in pairs(bufs) do
          if not filename or vim.fs.basename(path) == filename then
            dirty[buf] = true
          end
        end
      end
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
      local changed = function(filename)
        for buf, path in pairs(bufs) do
          if not filename or vim.fs.basename(path) == filename then
            dirty[buf] = true
          end
        end
      end
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
      return
    end

    watcher.bufs[buf] = path
    watchers[buf] = watcher
  end

  w.take = function()
    local changes = dirty
    dirty = {}
    return changes
  end

  return w
end

return M
