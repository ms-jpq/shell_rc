local lib = require "go.lib"

local M = {}

local d_watcher = {}
d_watcher.new = function(directory)
  local watcher = { directory = directory }

  local handle = vim.uv.new_fs_event()
  if not handle then
    return nil
  end

  local paths = {}
  local ok = handle:start(directory, {}, function(_, filename)
    if filename then
      local changed = paths[filename]
      if changed then
        changed()
      end
      return
    end

    for _, changed in pairs(paths) do
      changed()
    end
  end)
  if not ok then
    handle:close()
    return nil
  end

  watcher.add = function(path, changed)
    paths[vim.fs.basename(path)] = changed
  end

  watcher.remove = function(path)
    paths[vim.fs.basename(path)] = nil
    if next(paths) then
      return false
    end

    handle:stop()
    handle:close()
    return true
  end

  return watcher
end

local f_watcher = {}
f_watcher.new = function(path, changed)
  local watcher = {}

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
    return true
  end

  return watcher
end

M.new = function()
  local w = {}
  local dirty, entries, watchers = {}, {}, {}

  w.unwatch = function(buf)
    dirty[buf] = nil
    local file_watcher = watchers[buf]
    watchers[buf] = nil
    if file_watcher then
      file_watcher.remove(buf)
    end
  end

  local start_watcher = function(path)
    local file_watcher = entries[path]
    if file_watcher == nil then
      local watched = {}
      local notify = function()
        for buf in pairs(watched) do
          dirty[buf] = true
        end
      end

      local directory = vim.fs.dirname(path)
      local directory_key = directory .. lib.os.sep
      local directory_watcher = entries[directory_key]
      if directory_watcher == nil then
        directory_watcher = d_watcher.new(directory)
        entries[directory_key] = directory_watcher or false
      end

      local close = (function()
        if directory_watcher then
          directory_watcher.add(path, notify)
          return function()
            if directory_watcher.remove(path) then
              entries[directory_key] = nil
            end
          end
        else
          local path_watcher = f_watcher.new(path, notify)
          return path_watcher and path_watcher.close or nil
        end
      end)()
      if not close then
        return
      end

      file_watcher = { path = path }
      file_watcher.add = function(buf)
        watched[buf] = true
      end
      file_watcher.remove = function(buf)
        watched[buf] = nil
        if next(watched) then
          return false
        end

        close()
        entries[path] = nil
        return true
      end
      entries[path] = file_watcher
    elseif not file_watcher then
      return
    end

    return file_watcher
  end

  w.watch = function(buf, path)
    w.unwatch(buf)

    local file_watcher = start_watcher(path)
    if not file_watcher then
      return
    end

    file_watcher.add(buf)
    watchers[buf] = file_watcher
  end

  w.take = function()
    local changes = dirty
    dirty = {}
    return changes
  end

  return w
end

return M
