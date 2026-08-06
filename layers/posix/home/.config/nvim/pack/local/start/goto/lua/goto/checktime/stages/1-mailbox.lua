local async = require "goto.async"
local autocmd = require "goto.autocmd"
local lib = require "goto.lib"
local poll = require "goto.checktime.poll"
local snapshot = require "goto.checktime.snapshot"

local M = {}

local clone = function(value)
  local copied = {}
  for key, item in pairs(value) do
    copied[key] = item
  end
  return copied
end

---@alias ChecktimeChange "remote"|"local"
---@alias ChecktimeEvents table<ChecktimeChange, integer>
---@alias ChecktimeMailboxEventKind "track"|"recorded"|"changed"|"remote"|"rewatch"|"untrack"|"remember"|"writing"|"rewrite"|"rewrite-done"|"discard"|"finish"|"latest"|"restore"|"take"
---@alias ChecktimeInputPhase "active"|"closing"

---@class ChecktimeInput
---@field closing boolean

---@class ChecktimeRewrite
---@field before integer
---@field after? integer

---@class ChecktimeTracked
---@field base? string
---@field version? uv.fs_stat.result
---@field events? ChecktimeEvents
---@field input? ChecktimeInput
---@field rewrite? ChecktimeRewrite
---@field writing? boolean
---@field observing? integer
---@field path? string
---@field retry? string

---@class ChecktimeMailboxState
---@field entries table<string, ChecktimePoller>
---@field observed integer
---@field tracked table<integer, ChecktimeTracked>

---@class ChecktimeBatch
---@field base? string
---@field version? uv.fs_stat.result
---@field events ChecktimeEvents
---@field changedtick integer
---@field input? ChecktimeInput

---@class ChecktimeEventArgs
---@field buf integer

---@class ChecktimeMailboxEvent
---@field kind ChecktimeMailboxEventKind
---@field buf integer
---@field input? ChecktimeInputPhase
---@field seed? string
---@field base? string
---@field batch? ChecktimeBatch
---@field rewrite? ChecktimeRewrite
---@field value? boolean
---@field version? uv.fs_stat.result

---@class ChecktimeMailbox
---@field rewrite fun(buf: integer): fun()
---@field discard fun(buf: integer)
---@field finish fun(buf: integer)
---@field remember fun(buf: integer, base?: string, version?: uv.fs_stat.result)
---@field latest fun(buf: integer, batch: ChecktimeBatch): ChecktimeBatch
---@field restore fun(buf: integer, batch: ChecktimeBatch)
---@field take fun(): table<integer, ChecktimeBatch>
---@field writing fun(buf: integer, value: boolean)

---@class ChecktimeMailboxEvents
local EVENTS = {
  TRACK = "track",
  RECORDED = "recorded",
  CHANGED = "changed",
  REMOTE = "remote",
  REWATCH = "rewatch",
  UNTRACK = "untrack",
  REMEMBER = "remember",
  WRITING = "writing",
  REWRITE = "rewrite",
  REWRITE_DONE = "rewrite-done",
  DISCARD = "discard",
  FINISH = "finish",
  LATEST = "latest",
  RESTORE = "restore",
  TAKE = "take",
}

---@class ChecktimeInputPhases
local INPUTS = {
  ACTIVE = "active",
  CLOSING = "closing",
}

M.REMOTE, M.LOCAL = "remote", "local"

---@return ChecktimeMailbox
M.start = function()
  ---@type ChecktimeMailboxState
  local state = {
    entries = {},
    observed = 0,
    tracked = {},
  }
  ---@diagnostic disable-next-line: missing-fields
  local mb = {} ---@type ChecktimeMailbox

  local update = function(buf, fn)
    local tracked = clone(state.tracked)
    tracked[buf] = fn(clone(tracked[buf] or {}))
    state = { entries = state.entries, observed = state.observed, tracked = tracked }
    return tracked[buf]
  end

  local remove = function(buf)
    local tracked = clone(state.tracked)
    tracked[buf] = nil
    state = { entries = state.entries, observed = state.observed, tracked = tracked }
  end

  ---@param kind ChecktimeChange
  ---@param buf integer
  ---@param order? integer
  local mark = function(kind, buf, order)
    local observed = state.observed
    local current = order
    if current then
      observed = math.max(observed, current)
    else
      observed = observed + 1
      current = observed
    end
    state = { entries = state.entries, observed = observed, tracked = state.tracked }
    update(buf, function(tracked)
      local events = clone(tracked.events or {})
      events[kind] = math.max(events[kind] or 0, current)
      tracked.events = events
      return tracked
    end)
  end

  ---@param buf integer
  ---@param before integer
  ---@return integer
  local sample = function(buf, before)
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    if changedtick ~= before then
      mark(M.LOCAL, buf)
    end
    return changedtick
  end

  local attached = function(path)
    for _, tracked in pairs(state.tracked) do
      if tracked.path == path then
        return true
      end
    end
    return false
  end

  local release = function(path)
    if attached(path) then
      return
    end
    local watcher = state.entries[path]
    if not watcher then
      return
    end
    watcher.close()
    local entries = clone(state.entries)
    entries[path] = nil
    state = { entries = entries, observed = state.observed, tracked = state.tracked }
  end

  local detach = function(buf)
    local tracked = state.tracked[buf]
    if not tracked then
      return
    end
    local path = tracked.path
    update(buf, function(next)
      next.path, next.retry = nil, nil
      return next
    end)
    if path then
      release(path)
    end
  end

  local dispatch

  local mark_path = function(path)
    for buf, tracked in pairs(state.tracked) do
      if tracked.path == path then
        mark(M.REMOTE, buf)
      end
    end
  end

  local watcher_for = function(path)
    local watcher = state.entries[path]
    if watcher then
      return watcher
    end
    local started = poll.start(
      path,
      vim.schedule_wrap(function()
        mark_path(path)
      end)
    )
    if not started then
      return nil
    end
    local entries = clone(state.entries)
    entries[path] = started
    state = { entries = entries, observed = state.observed, tracked = state.tracked }
    return started
  end

  local attach = function(buf, path)
    update(buf, function(tracked)
      tracked.retry = path
      return tracked
    end)
    if watcher_for(path) then
      update(buf, function(tracked)
        tracked.path, tracked.retry = path, nil
        return tracked
      end)
    end
  end

  local watch = function(buf)
    local path = vim.bo[buf].modifiable and vim.api.nvim_buf_get_name(buf) or nil
    local tracked = state.tracked[buf]
    if tracked and tracked.path == path and not tracked.retry then
      return
    end
    detach(buf)
    if path and path ~= "" then
      attach(buf, path)
    end
  end

  local remember = function(buf, base, version)
    update(buf, function(tracked)
      tracked.base, tracked.version = base, version
      return tracked
    end)
  end

  local writing = function(buf, value)
    update(buf, function(tracked)
      tracked.writing = value
      return tracked
    end)
  end

  local rewrite = function(buf)
    local rewrite = { before = vim.api.nvim_buf_get_changedtick(buf) } ---@type ChecktimeRewrite
    update(buf, function(tracked)
      tracked.rewrite = rewrite
      return tracked
    end)
    return function()
      dispatch { kind = EVENTS.REWRITE_DONE, buf = buf, rewrite = rewrite }
    end
  end

  local rewrite_done = function(buf, rewrite)
    update(buf, function(tracked)
      if tracked.rewrite == rewrite then
        local completed = clone(rewrite)
        completed.after = vim.api.nvim_buf_get_changedtick(buf)
        tracked.rewrite = completed
      end
      return tracked
    end)
  end

  local discard = function(buf)
    update(buf, function(tracked)
      tracked.rewrite, tracked.input = nil, nil
      return tracked
    end)
  end

  local finish = function(buf)
    local tracked = state.tracked[buf]
    if tracked and tracked.input and tracked.input.closing then
      update(buf, function(next)
        next.input = nil
        return next
      end)
      if vim.bo[buf].modified then
        mark(M.LOCAL, buf)
      end
    end
  end

  local changed = function(buf)
    local rewrite = state.tracked[buf] and state.tracked[buf].rewrite
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    update(buf, function(tracked)
      tracked.rewrite = nil
      return tracked
    end)
    if rewrite and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after) then
      return false
    end
    return true
  end

  local rewatch = function(buf)
    watch(buf)
    if vim.bo[buf].modifiable then
      mark(M.REMOTE, buf)
    end
  end

  local latest = function(buf, batch)
    local changedtick = sample(buf, batch.changedtick)
    local tracked = state.tracked[buf]
    local pending = tracked and tracked.events or {}
    local local_order = math.max(batch.events[M.LOCAL] or 0, pending[M.LOCAL] or 0)
    local remote_order = math.max(batch.events[M.REMOTE] or 0, pending[M.REMOTE] or 0)
    local events = {} ---@type ChecktimeEvents
    if local_order > 0 then
      events[M.LOCAL] = local_order
    end
    if remote_order > 0 then
      events[M.REMOTE] = remote_order
    end
    return {
      base = batch.base,
      version = batch.version,
      events = events,
      changedtick = changedtick,
      input = tracked and tracked.input or nil,
    }
  end

  local restore = function(buf, batch)
    sample(buf, batch.changedtick)
    for kind, order in pairs(batch.events) do
      mark(kind, buf, order)
    end
  end

  local take = function()
    for buf, tracked in pairs(state.tracked) do
      if tracked.retry and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable then
        rewatch(buf)
      end
    end
    local previous = state
    local tracked = clone(previous.tracked)
    local batches = {} ---@type table<integer, ChecktimeBatch>
    for buf, item in pairs(previous.tracked) do
      if not item.observing and not item.writing and (item.path or item.retry) and item.events then
        local next = clone(item)
        next.events = nil
        tracked[buf] = next
        batches[buf] = {
          base = item.base,
          version = item.version,
          events = item.events,
          changedtick = vim.api.nvim_buf_get_changedtick(buf),
          input = item.input,
        }
      end
    end
    state = { entries = previous.entries, observed = previous.observed, tracked = tracked }
    return batches
  end

  local emit = async(function(event)
    return dispatch(event)
  end)

  dispatch = function(event)
    if event.kind == EVENTS.TRACK then
      local seed = snapshot.current(event.buf).text
      update(event.buf, function(tracked)
        tracked.base, tracked.observing, tracked.version = seed, (tracked.observing or 0) + 1, nil
        return tracked
      end)
      watch(event.buf)
      mark(M.REMOTE, event.buf)
      emit { kind = EVENTS.RECORDED, buf = event.buf, seed = seed }
    elseif event.kind == EVENTS.RECORDED then
      local tracked = state.tracked[event.buf] or {}
      local writing = tracked.writing
      local base = event.seed or (writing and snapshot.current(event.buf).text or nil)
      if not event.seed then
        update(event.buf, function(next)
          next.observing = (next.observing or 0) + 1
          return next
        end)
      end
      if not writing then
        discard(event.buf)
      end
      local read, version, remote = snapshot.read(event.buf)
      update(event.buf, function(next)
        assert(next.observing)
        next.observing = next.observing == 1 and nil or next.observing - 1
        next.writing = nil
        return next
      end)
      if not vim.api.nvim_buf_is_valid(event.buf) then
        return
      elseif read == snapshot.STATES.RETRY then
        mark(M.REMOTE, event.buf)
      elseif read == snapshot.STATES.RECONCILE then
        remember(event.buf, base or remote, version)
        if writing then
          mark(M.REMOTE, event.buf)
        end
      elseif read == snapshot.STATES.OPAQUE then
        remember(event.buf, base, version)
        if writing then
          mark(M.REMOTE, event.buf)
        end
      elseif read == snapshot.STATES.NONE then
        remember(event.buf, base, version)
        if writing then
          mark(M.REMOTE, event.buf)
        end
      else
        assert(false, vim.inspect(read))
      end
    elseif event.kind == EVENTS.CHANGED then
      if event.input == INPUTS.CLOSING then
        update(event.buf, function(tracked)
          if tracked.input then
            tracked.input = { closing = true }
          end
          return tracked
        end)
        mark(M.LOCAL, event.buf)
      elseif changed(event.buf) then
        if event.input == INPUTS.ACTIVE then
          update(event.buf, function(tracked)
            tracked.input = { closing = false }
            return tracked
          end)
        elseif event.input then
          assert(false, vim.inspect(event))
        end
        mark(M.LOCAL, event.buf)
      end
    elseif event.kind == EVENTS.REMOTE then
      mark(M.REMOTE, event.buf)
    elseif event.kind == EVENTS.REWATCH then
      rewatch(event.buf)
    elseif event.kind == EVENTS.UNTRACK then
      detach(event.buf)
      remove(event.buf)
    elseif event.kind == EVENTS.REMEMBER then
      remember(event.buf, event.base, event.version)
    elseif event.kind == EVENTS.WRITING then
      assert(event.value ~= nil)
      writing(event.buf, event.value)
    elseif event.kind == EVENTS.REWRITE then
      return rewrite(event.buf)
    elseif event.kind == EVENTS.REWRITE_DONE then
      rewrite_done(event.buf, assert(event.rewrite))
    elseif event.kind == EVENTS.DISCARD then
      discard(event.buf)
    elseif event.kind == EVENTS.FINISH then
      finish(event.buf)
    elseif event.kind == EVENTS.LATEST then
      return latest(event.buf, assert(event.batch))
    elseif event.kind == EVENTS.RESTORE then
      restore(event.buf, assert(event.batch))
    elseif event.kind == EVENTS.TAKE then
      return take()
    else
      assert(false, vim.inspect(event))
    end
  end

  vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
    group = lib.group,
    command = [[silent! wall! ++p]],
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = function()
      vim.v.fcs_choice = ""
    end,
  })

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost", "BufFilePost" }, {
    group = lib.group,
    callback = function(args)
      emit { kind = EVENTS.TRACK, buf = args.buf }
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedP" }, {
    group = lib.group,
    callback = function(args)
      emit { kind = EVENTS.CHANGED, buf = args.buf }
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChangedI" }, {
    group = lib.group,
    callback = function(args)
      emit { kind = EVENTS.CHANGED, buf = args.buf, input = INPUTS.ACTIVE }
    end,
  })

  autocmd.insert_leave({}, function(args)
    emit { kind = EVENTS.CHANGED, buf = args.buf, input = INPUTS.CLOSING }
  end)

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      emit { kind = EVENTS.RECORDED, buf = args.buf }
    end,
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      emit { kind = EVENTS.UNTRACK, buf = args.buf }
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained" }, {
    group = lib.group,
    callback = function()
      for buf, tracked in pairs(state.tracked) do
        if tracked.path then
          emit { kind = EVENTS.REMOTE, buf = buf }
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = "modifiable",
    callback = function()
      emit { kind = EVENTS.REWATCH, buf = vim.api.nvim_get_current_buf() }
    end,
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        emit { kind = EVENTS.TRACK, buf = buf }
      end
    end
  end)

  mb.discard = function(buf)
    dispatch { kind = EVENTS.DISCARD, buf = buf }
  end
  mb.finish = function(buf)
    dispatch { kind = EVENTS.FINISH, buf = buf }
  end
  mb.latest = function(buf, batch)
    local result = dispatch { kind = EVENTS.LATEST, buf = buf, batch = batch }
    ---@cast result ChecktimeBatch
    return result
  end
  mb.remember = function(buf, base, version)
    dispatch { kind = EVENTS.REMEMBER, buf = buf, base = base, version = version }
  end
  mb.restore = function(buf, batch)
    dispatch { kind = EVENTS.RESTORE, buf = buf, batch = batch }
  end
  mb.rewrite = function(buf)
    local result = dispatch { kind = EVENTS.REWRITE, buf = buf }
    ---@cast result fun()
    return result
  end
  mb.take = function()
    local result = dispatch { kind = EVENTS.TAKE, buf = 0 }
    ---@cast result table<integer, ChecktimeBatch>
    return result
  end
  mb.writing = function(buf, value)
    dispatch { kind = EVENTS.WRITING, buf = buf, value = value }
  end
  return mb
end

return M
