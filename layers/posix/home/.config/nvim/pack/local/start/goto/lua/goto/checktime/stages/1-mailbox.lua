local async = require "goto.async"
local autocmd = require "goto.autocmd"
local lib = require "goto.lib"
local snapshot = require "goto.checktime.snapshot"
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
---@field base? string
---@field version? uv.fs_stat.result
---@field events? ChecktimeEvents
---@field rewrite? ChecktimeRewrite
---@field writing? boolean
---@field observing? integer
---@field epoch? integer
---@field observed? integer

---@class ChecktimeBatch
---@field base? string
---@field version? uv.fs_stat.result
---@field events ChecktimeEvents
---@field changedtick integer

---@class ChecktimeObserve
---@field kind "observe"
---@field buf integer
---@field base string
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

---@class ChecktimeDiscard
---@field kind "discard"
---@field buf integer

---@class ChecktimeRemember
---@field kind "remember"
---@field buf integer
---@field base? string
---@field version? uv.fs_stat.result

---@class ChecktimeRestore
---@field kind "restore"
---@field buf integer
---@field batch ChecktimeBatch

---@class ChecktimeRewriteEvent
---@field kind "rewrite"
---@field buf integer
---@field rewrite ChecktimeRewrite
---@field done boolean

---@class ChecktimeWriting
---@field kind "writing"
---@field buf integer
---@field value boolean

---@class ChecktimeSample
---@field kind "sample"
---@field buf integer
---@field changedtick integer

---@alias ChecktimeMailboxEvent ChecktimeObserve|ChecktimeDirtyLocal|ChecktimeDirtyRemote|ChecktimeDiscard|ChecktimeRemember|ChecktimeRestore|ChecktimeRewriteEvent|ChecktimeSample|ChecktimeWriting

---@class ChecktimeAutocmdArgs
---@field buf integer

---@class ChecktimeMailbox
---@field dispatch fun(event: ChecktimeMailboxEvent)
---@field latest fun(buf: integer, batch: ChecktimeBatch): ChecktimeBatch
---@field take fun(): table<integer, ChecktimeBatch>

---@class ChecktimeMailboxEvents
M.EVENTS = {
  DIRTY = "dirty",
  DISCARD = "discard",
  OBSERVE = "observe",
  REMEMBER = "remember",
  RESTORE = "restore",
  REWRITE = "rewrite",
  SAMPLE = "sample",
  WRITING = "writing",
}

local REMOTE, LOCAL = "remote", "local"
local RELOADING = "__checktime_reloading__"
local TRACKED = "__checktime_mailbox__"

---@param buf integer
---@param fn fun()
---@return boolean
M.reloading = function(buf, fn)
  vim.b[buf][RELOADING] = true
  local ok = pcall(fn)
  vim.b[buf][RELOADING] = nil
  return ok
end

---@return ChecktimeMailbox
M.start = function()
  local EVENTS = M.EVENTS
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

  local watches = watcher.start {
    changed = function(buf)
      mb.dispatch { kind = EVENTS.DIRTY, change = REMOTE, buf = buf, watch = false }
    end,
  }

  ---@param event ChecktimeMailboxEvent
  mb.dispatch = function(event)
    if not vim.api.nvim_buf_is_valid(event.buf) then
      return
    end
    if event.kind == EVENTS.OBSERVE then
      local tracked = vim.b[event.buf][TRACKED] or {}
      local epoch = event.track and (tracked.observed or 0) + 1 or tracked.epoch
      local writing = tracked.writing
      if not event.track and writing then
        return
      end

      local base = event.base
      update(event.buf, function(next)
        if event.track then
          next.base, next.version, next.epoch = base, nil, epoch
          next.observing = 1
        else
          next.observing = (next.observing or 0) + 1
        end
        next.rewrite = nil
        return next
      end)
      if event.track then
        watches.update(event.buf, vim.bo[event.buf].modifiable and vim.api.nvim_buf_get_name(event.buf) or "")
        mark(REMOTE, event.buf)
      end
      local read, version, text = snapshot.read(event.buf)
      if not vim.api.nvim_buf_is_valid(event.buf) then
        return
      end

      local current = vim.b[event.buf][TRACKED]
      if not current or current.epoch ~= epoch or not current.observing then
        return
      end

      update(event.buf, function(next)
        assert(next.observing)
        if next.observing == 1 then
          next.observing = nil
        else
          next.observing = next.observing - 1
        end
        return next
      end)

      if read == snapshot.STATES.RETRY then
        mark(REMOTE, event.buf)
      elseif read == snapshot.STATES.RECONCILE then
        mb.dispatch { kind = EVENTS.REMEMBER, buf = event.buf, base = event.track and base or text, version = version }
      elseif read == snapshot.STATES.OPAQUE or read == snapshot.STATES.NONE then
        mb.dispatch { kind = EVENTS.REMEMBER, buf = event.buf, base = event.track and base or nil, version = version }
      else
        error(vim.inspect(read))
      end
    elseif event.kind == EVENTS.DIRTY then
      if event.change == LOCAL then
        local tracked = vim.b[event.buf][TRACKED]
        local rewrite = tracked and tracked.rewrite
        local changedtick = vim.api.nvim_buf_get_changedtick(event.buf)
        update(event.buf, function(trk)
          trk.rewrite = nil
          return trk
        end)

        if rewrite and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after) then
          return
        end
        mark(LOCAL, event.buf)
      elseif event.change == REMOTE then
        if event.watch then
          watches.update(event.buf, vim.bo[event.buf].modifiable and vim.api.nvim_buf_get_name(event.buf) or "")
        end

        if not event.watch or vim.bo[event.buf].modifiable then
          mark(REMOTE, event.buf)
        end
      else
        error(vim.inspect(event))
      end
    elseif event.kind == EVENTS.DISCARD then
      update(event.buf, function(tracked)
        tracked.rewrite = nil
        return tracked
      end)
    elseif event.kind == EVENTS.REMEMBER then
      update(event.buf, function(tracked)
        tracked.base, tracked.version = event.base, event.version
        return tracked
      end)
    elseif event.kind == EVENTS.RESTORE then
      local batch = assert(event.batch)
      for kind, order in pairs(batch.events) do
        mark(kind, event.buf, order)
      end
    elseif event.kind == EVENTS.REWRITE then
      local rewrite = event.rewrite
      update(event.buf, function(tracked)
        if not event.done then
          tracked.rewrite = rewrite
        elseif tracked.rewrite == rewrite then
          local completed = clone(rewrite)
          completed.after = vim.api.nvim_buf_get_changedtick(event.buf)
          tracked.rewrite = completed
        end
        return tracked
      end)
    elseif event.kind == EVENTS.SAMPLE then
      if vim.api.nvim_buf_get_changedtick(event.buf) ~= event.changedtick then
        mark(LOCAL, event.buf)
      end
    elseif event.kind == EVENTS.WRITING then
      update(event.buf, function(tracked)
        tracked.writing = event.value
        return tracked
      end)
    else
      error(vim.inspect(event))
    end
  end

  ---@param buf integer
  ---@param batch ChecktimeBatch
  ---@return ChecktimeBatch
  mb.latest = function(buf, batch)
    local tracked = vim.b[buf][TRACKED]
    local pending = tracked and tracked.events or {}
    local local_order = math.max(batch.events[LOCAL] or 0, pending[LOCAL] or 0)
    local remote_order = math.max(batch.events[REMOTE] or 0, pending[REMOTE] or 0)
    local events = {} ---@type ChecktimeEvents
    if local_order > 0 then
      events[LOCAL] = local_order
    end
    if remote_order > 0 then
      events[REMOTE] = remote_order
    end
    return {
      base = batch.base,
      version = batch.version,
      events = events,
      changedtick = vim.api.nvim_buf_get_changedtick(buf),
    }
  end

  ---@return table<integer, ChecktimeBatch>
  mb.take = function()
    watches.retry()
    local batches = {} ---@type table<integer, ChecktimeBatch>
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      local item = vim.b[buf][TRACKED]
      if item and not item.observing and not item.writing and watches.has(buf) and item.events then
        update(buf, function(next)
          next.events = nil
          return next
        end)
        batches[buf] = {
          base = item.base,
          version = item.version,
          events = item.events,
          changedtick = vim.api.nvim_buf_get_changedtick(buf),
        }
      end
    end
    return batches
  end

  do
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
        mb.dispatch { kind = EVENTS.OBSERVE, buf = args.buf, base = snapshot.current(args.buf).text, track = true }
      end),
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = async(function(args)
        mb.dispatch { kind = EVENTS.DIRTY, change = LOCAL, buf = args.buf }
      end),
    })

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = async(function(args)
        mb.dispatch { kind = EVENTS.OBSERVE, buf = args.buf, base = snapshot.current(args.buf).text, track = false }
      end),
    })

    vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
      group = lib.group,
      callback = function(event)
        vim.b[event.buf][TRACKED] = nil
      end,
    })

    vim.api.nvim_create_autocmd({ "FocusGained" }, {
      group = lib.group,
      callback = async(function()
        watches.refresh()
      end),
    })

    vim.api.nvim_create_autocmd({ "OptionSet" }, {
      group = lib.group,
      pattern = "modifiable",
      callback = async(function()
        mb.dispatch { kind = EVENTS.DIRTY, change = REMOTE, buf = vim.api.nvim_get_current_buf(), watch = true }
      end),
    })

    autocmd.vim_enter(function()
      for _, buf in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          mb.dispatch { kind = EVENTS.OBSERVE, buf = buf, base = snapshot.current(buf).text, track = true }
        end
      end
    end)
  end

  return mb
end

return M
