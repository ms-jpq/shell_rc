local async = require "goto.async"
local autocmd = require "goto.autocmd"
local lib = require "goto.lib"
local snapshotter = require "goto.checktime.snapshotter"
local watcher = require "goto.checktime.watcher"

local M = {}

---@generic T: table
---@param value T
---@return T
local clone = function(value)
  local copied = {}
  for key, item in pairs(value) do
    copied[key] = item
  end
  return copied
end

---@alias ChecktimeChange "remote"|"local"
---@alias ChecktimeEvents table<ChecktimeChange, integer>

---@class ChecktimeRewrite
---@field before integer
---@field after? integer

---@class ChecktimeTracked
---@field accepted? string
---@field version? uv.fs_stat.result
---@field events? ChecktimeEvents
---@field observing? integer
---@field epoch? integer
---@field observed? integer

---@class ChecktimeBatch
---@field accepted? string
---@field version? uv.fs_stat.result
---@field events ChecktimeEvents
---@field changedtick integer

---@class ChecktimeObserve
---@field kind "observe"
---@field buf integer
---@field text string
---@field track boolean

---@class ChecktimeDirtyLocal
---@field kind "dirty"
---@field buf integer
---@field change "local"

---@class ChecktimeDirtyRemote
---@field kind "dirty"
---@field buf integer
---@field change "remote"
---@field watch boolean

---@class ChecktimeAccepted
---@field text string
---@field version? uv.fs_stat.result

---@class ChecktimeCommit
---@field buf integer
---@field accepted? ChecktimeAccepted
---@field batch? ChecktimeBatch
---@field discard? boolean

---@class ChecktimeCommitEvent: ChecktimeCommit
---@field kind "commit"

---@alias ChecktimeMailboxAction ChecktimeObserve|ChecktimeDirtyLocal|ChecktimeDirtyRemote|ChecktimeCommitEvent

---@class ChecktimeAutocmdArgs
---@field buf integer

---@class ChecktimeMailbox
---@field commit fun(change: ChecktimeCommit)
---@field latest fun(buf: integer, changedtick: integer): ChecktimeBatch?
---@field take fun(): table<integer, integer>

local EVENTS = {
  COMMIT = "commit",
  DIRTY = "dirty",
  OBSERVE = "observe",
}

local REMOTE, LOCAL = "remote", "local"
local RELOADING = "__checktime_reloading__"
local REWRITE = "__checktime_rewrite__"
local TRACKED = "__checktime_mailbox__"
local WRITING = "__checktime_writing__"

local reloading = function(buf)
  return vim.b[buf][RELOADING]
end

---@param buf integer
---@param fn fun()
---@return boolean
M.reloading = function(buf, fn)
  vim.b[buf][RELOADING] = true
  local ok = pcall(fn)
  vim.b[buf][RELOADING] = nil
  return ok
end

---@param buf integer
---@param fn fun()
M.rewriting = function(buf, fn)
  local rewrite = { before = vim.api.nvim_buf_get_changedtick(buf) } ---@type ChecktimeRewrite
  vim.b[buf][REWRITE] = rewrite
  fn()
  rewrite.after = vim.api.nvim_buf_get_changedtick(buf)
  vim.b[buf][REWRITE] = rewrite
end

---@param buf integer
---@param value boolean
M.writing = function(buf, value)
  vim.b[buf][WRITING] = value or nil
end

---@return ChecktimeMailbox
M.start = function()
  ---@diagnostic disable-next-line: missing-fields
  local mb = {} ---@type ChecktimeMailbox

  ---@param buf integer
  ---@param fn fun(tracked: ChecktimeTracked): ChecktimeTracked
  ---@return ChecktimeTracked
  local update = function(buf, fn)
    local tracked = fn(clone(vim.b[buf][TRACKED] or {}))
    vim.b[buf][TRACKED] = tracked
    return tracked
  end

  ---@param buf integer
  ---@param text? string
  ---@param version? uv.fs_stat.result
  local accept = function(buf, text, version)
    update(buf, function(tracked)
      tracked.accepted, tracked.version = text, version
      return tracked
    end)
  end

  ---@param kind ChecktimeChange
  ---@param buf integer
  ---@param order? integer
  local mark = function(kind, buf, order)
    update(buf, function(tracked)
      local observed = tracked.observed or 0
      local current = order
      if current then
        observed = math.max(observed, current)
      else
        observed = observed + 1
        current = observed
      end
      local events = clone(tracked.events or {})
      events[kind] = math.max(events[kind] or 0, current)
      tracked.events, tracked.observed = events, observed
      return tracked
    end)
  end

  local watches ---@type ChecktimeWatcher

  ---@param action ChecktimeMailboxAction
  local dispatch = function(action)
    if not vim.api.nvim_buf_is_valid(action.buf) then
      return
    end
    if action.kind == EVENTS.COMMIT then
      update(action.buf, function(tracked)
        if action.accepted then
          tracked.accepted, tracked.version = action.accepted.text, action.accepted.version
        end
        if action.batch then
          local events = clone(tracked.events or {})
          for kind, order in pairs(action.batch.events) do
            if events[kind] == order then
              events[kind] = nil
            end
          end
          tracked.events = next(events) and events or nil
        end
        return tracked
      end)

      if action.discard then
        vim.b[action.buf][REWRITE] = nil
      end
      return
    elseif action.kind == EVENTS.DIRTY then
      if action.change == LOCAL then
        local rewrite = vim.b[action.buf][REWRITE]
        local changedtick = vim.api.nvim_buf_get_changedtick(action.buf)
        vim.b[action.buf][REWRITE] = nil

        if rewrite and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after) then
          return
        end

        mark(LOCAL, action.buf)
      elseif action.change == REMOTE then
        if action.watch then
          watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
        end

        if not action.watch or vim.bo[action.buf].modifiable then
          mark(REMOTE, action.buf)
        end
      else
        assert(false, vim.inspect(action))
      end
      return
    elseif action.kind == EVENTS.OBSERVE then
      local tracked = vim.b[action.buf][TRACKED] or {}
      local epoch = action.track and (tracked.observed or 0) + 1 or tracked.epoch
      local writing = vim.b[action.buf][WRITING]
      if not action.track and writing then
        return
      end

      local source = action.text
      update(action.buf, function(next)
        if action.track then
          next.accepted, next.version, next.epoch = source, nil, epoch
          next.observing = 1
        else
          next.observing = (next.observing or 0) + 1
        end
        return next
      end)

      vim.b[action.buf][REWRITE] = nil
      if action.track then
        watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
        mark(REMOTE, action.buf)
      end

      local read, version, text = snapshotter.read(action.buf)
      if not vim.api.nvim_buf_is_valid(action.buf) then
        return
      end
      local current = vim.b[action.buf][TRACKED]
      if not current or current.epoch ~= epoch or not current.observing then
        return
      end

      update(action.buf, function(next)
        assert(next.observing)
        if next.observing == 1 then
          next.observing = nil
        else
          next.observing = next.observing - 1
        end
        return next
      end)

      if read == snapshotter.STATES.RETRY then
        mark(REMOTE, action.buf)
      elseif read == snapshotter.STATES.RECONCILE then
        accept(action.buf, action.track and source or text, version)
      elseif read == snapshotter.STATES.OPAQUE or read == snapshotter.STATES.NONE then
        accept(action.buf, action.track and source or nil, version)
      else
        assert(false, vim.inspect(read))
      end
    else
      assert(false, vim.inspect(action))
    end
  end

  watches = watcher.start {
    changed = function(buf)
      dispatch { kind = EVENTS.DIRTY, change = REMOTE, buf = buf, watch = false }
    end,
    reloading = reloading,
  }

  ---@param buf integer
  ---@param before integer
  ---@return ChecktimeBatch?
  mb.latest = function(buf, before)
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    if changedtick ~= before then
      mark(LOCAL, buf)
    end
    local tracked = vim.b[buf][TRACKED]
    if not tracked or not tracked.events then
      return nil
    end
    return {
      accepted = tracked.accepted,
      version = tracked.version,
      events = tracked.events,
      changedtick = changedtick,
    }
  end

  ---@return table<integer, integer>
  mb.take = function()
    watches.retry()
    local ready = {} ---@type table<integer, integer>
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      local item = vim.b[buf][TRACKED]
      if item and not item.observing and not vim.b[buf][WRITING] and watches.has(buf) and item.events then
        ready[buf] = vim.api.nvim_buf_get_changedtick(buf)
      end
    end
    return ready
  end

  ---@param change ChecktimeCommit
  mb.commit = function(change)
    dispatch {
      kind = EVENTS.COMMIT,
      buf = change.buf,
      accepted = change.accepted,
      batch = change.batch,
      discard = change.discard,
    }
  end

  do
    snapshotter.start(function(buf)
      dispatch { kind = EVENTS.DIRTY, change = REMOTE, buf = buf, watch = false }
    end)

    vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
      group = lib.group,
      command = [[silent! wall! ++p]],
    })

    vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
      group = lib.group,
      callback = async(function()
        vim.v.fcs_choice = ""
      end),
    })

    vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost", "BufFilePost" }, {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = async(function(args)
        if vim.b[args.buf][RELOADING] then
          return
        end
        dispatch { kind = EVENTS.OBSERVE, buf = args.buf, text = snapshotter.current(args.buf).text, track = true }
      end),
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = async(function(args)
        dispatch { kind = EVENTS.DIRTY, change = LOCAL, buf = args.buf, watch = false }
      end),
    })

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = async(function(args)
        dispatch { kind = EVENTS.OBSERVE, buf = args.buf, text = snapshotter.current(args.buf).text, track = false }
      end),
    })

    vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
      group = lib.group,
      callback = function(event)
        if not reloading(event.buf) then
          vim.b[event.buf][TRACKED] = nil
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "OptionSet" }, {
      group = lib.group,
      pattern = "modifiable",
      callback = async(function()
        dispatch { kind = EVENTS.DIRTY, change = REMOTE, buf = vim.api.nvim_get_current_buf(), watch = true }
      end),
    })

    autocmd.vim_enter(function()
      for _, buf in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
          dispatch { kind = EVENTS.OBSERVE, buf = buf, text = snapshotter.current(buf).text, track = true }
        end
      end
    end)
  end

  return mb
end

return M
