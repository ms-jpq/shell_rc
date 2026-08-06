local async = require "goto.async"
local autocmd = require "goto.autocmd"
local lib = require "goto.lib"
local poll = require "goto.checktime.poll"
local snapshot = require "goto.checktime.snapshot"

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

---@class ChecktimeObserve
---@field kind "observe"
---@field buf integer
---@field base string
---@field track boolean

---@class ChecktimeDirtyLocal
---@field kind "dirty"
---@field buf integer
---@field change "local"
---@field insert? boolean

---@class ChecktimeDirtyRemote
---@field kind "dirty"
---@field buf integer
---@field change "remote"
---@field watch boolean

---@class ChecktimeDetach
---@field kind "detach"
---@field buf integer

---@class ChecktimeDiscard
---@field kind "discard"
---@field buf integer

---@class ChecktimeFinish
---@field kind "finish"
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

---@alias ChecktimeMailboxEvent ChecktimeObserve|ChecktimeDirtyLocal|ChecktimeDirtyRemote|ChecktimeDetach|ChecktimeDiscard|ChecktimeFinish|ChecktimeRemember|ChecktimeRestore|ChecktimeRewriteEvent|ChecktimeSample|ChecktimeWriting

---@class ChecktimeAutocmdArgs
---@field buf integer

---@class ChecktimeMailbox
---@field dispatch fun(event: ChecktimeMailboxEvent)
---@field latest fun(buf: integer, batch: ChecktimeBatch): ChecktimeBatch
---@field take fun(): table<integer, ChecktimeBatch>

---@class ChecktimeMailboxEvents
M.EVENTS = {
  DETACH = "detach",
  DIRTY = "dirty",
  DISCARD = "discard",
  FINISH = "finish",
  OBSERVE = "observe",
  REMEMBER = "remember",
  RESTORE = "restore",
  REWRITE = "rewrite",
  SAMPLE = "sample",
  WRITING = "writing",
}

local REMOTE, LOCAL = "remote", "local"

---@return ChecktimeMailbox
M.start = function()
  local EVENTS = M.EVENTS
  ---@type ChecktimeMailboxState
  local state = {
    entries = {},
    observed = 0,
    tracked = {},
  }
  ---@diagnostic disable-next-line: missing-fields
  local mb = {} ---@type ChecktimeMailbox

  ---@param buf integer
  ---@param fn fun(tracked: ChecktimeTracked): ChecktimeTracked
  ---@return ChecktimeTracked
  local update = function(buf, fn)
    local tracked = clone(state.tracked)
    tracked[buf] = fn(clone(tracked[buf] or {}))
    state = { entries = state.entries, observed = state.observed, tracked = tracked }
    return tracked[buf]
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
    local tracked = clone(state.tracked)
    local item = clone(tracked[buf] or {})
    local events = clone(item.events or {})
    events[kind] = math.max(events[kind] or 0, current)
    item.events = events
    tracked[buf] = item
    state = { entries = state.entries, observed = observed, tracked = tracked }
  end

  ---@param buf integer
  ---@param path string
  local watch = function(buf, path)
    local tracked = state.tracked[buf]
    if tracked and tracked.path == path and not tracked.retry then
      return
    end
    local previous = tracked and tracked.path
    update(buf, function(next)
      next.path, next.retry = nil, nil
      return next
    end)
    if previous then
      local attached = false
      for _, next in pairs(state.tracked) do
        if next.path == previous then
          attached = true
          break
        end
      end
      local watcher = state.entries[previous]
      if watcher and not attached then
        watcher.close()
        local entries = clone(state.entries)
        entries[previous] = nil
        state = { entries = entries, observed = state.observed, tracked = state.tracked }
      end
    end
    if path ~= "" then
      update(buf, function(next)
        next.retry = path
        return next
      end)
      local watcher = state.entries[path] ---@type ChecktimePoller?
      if not watcher then
        watcher = poll.start(
          path,
          vim.schedule_wrap(async(function()
            for current, next in pairs(state.tracked) do
              if next.path == path then
                mb.dispatch { kind = EVENTS.DIRTY, change = REMOTE, buf = current, watch = false }
              end
            end
          end))
        )
        if watcher then
          local entries = clone(state.entries)
          entries[path] = watcher
          state = { entries = entries, observed = state.observed, tracked = state.tracked }
        end
      end
      if watcher then
        update(buf, function(next)
          next.path, next.retry = path, nil
          return next
        end)
      end
    end
  end

  ---@param event ChecktimeMailboxEvent
  mb.dispatch = function(event)
    if event.kind == EVENTS.OBSERVE then
      local tracked = state.tracked[event.buf] or {}
      local writing = tracked.writing
      local base = assert(event.base)
      if event.track then
        update(event.buf, function(next)
          next.base, next.version = base, nil
          return next
        end)
        watch(event.buf, vim.bo[event.buf].modifiable and vim.api.nvim_buf_get_name(event.buf) or "")
      end
      update(event.buf, function(next)
        next.observing = (next.observing or 0) + 1
        return next
      end)
      if event.track then
        mark(REMOTE, event.buf)
      end
      if not writing then
        update(event.buf, function(next)
          next.rewrite, next.input = nil, nil
          return next
        end)
      end
      local read, version = snapshot.read(event.buf)
      update(event.buf, function(next)
        assert(next.observing)
        if next.observing == 1 then
          next.observing = nil
        else
          next.observing = next.observing - 1
        end
        next.writing = nil
        return next
      end)
      if not vim.api.nvim_buf_is_valid(event.buf) then
        return
      elseif read == snapshot.STATES.RETRY then
        mark(REMOTE, event.buf)
      elseif read == snapshot.STATES.RECONCILE or read == snapshot.STATES.OPAQUE or read == snapshot.STATES.NONE then
        mb.dispatch { kind = EVENTS.REMEMBER, buf = event.buf, base = base, version = version }
      else
        error(vim.inspect(read))
      end
      if read ~= snapshot.STATES.RETRY and writing then
        mark(REMOTE, event.buf)
      end
    elseif event.kind == EVENTS.DIRTY then
      if event.change == LOCAL then
        if event.insert == false then
          update(event.buf, function(tracked)
            if tracked.input then
              tracked.input = { closing = true }
            end
            return tracked
          end)
          mark(LOCAL, event.buf)
        else
          local rewrite = state.tracked[event.buf] and state.tracked[event.buf].rewrite
          local changedtick = vim.api.nvim_buf_get_changedtick(event.buf)
          update(event.buf, function(tracked)
            tracked.rewrite = nil
            return tracked
          end)
          if rewrite and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after) then
            return
          elseif event.insert then
            update(event.buf, function(tracked)
              tracked.input = { closing = false }
              return tracked
            end)
          end
          mark(LOCAL, event.buf)
        end
      elseif event.change == REMOTE then
        if event.watch then
          watch(event.buf, vim.bo[event.buf].modifiable and vim.api.nvim_buf_get_name(event.buf) or "")
        end
        if not event.watch or vim.bo[event.buf].modifiable then
          mark(REMOTE, event.buf)
        end
      else
        error(vim.inspect(event))
      end
    elseif event.kind == EVENTS.DETACH then
      watch(event.buf, "")
      local tracked = clone(state.tracked)
      tracked[event.buf] = nil
      state = { entries = state.entries, observed = state.observed, tracked = tracked }
    elseif event.kind == EVENTS.DISCARD then
      update(event.buf, function(tracked)
        tracked.rewrite, tracked.input = nil, nil
        return tracked
      end)
    elseif event.kind == EVENTS.FINISH then
      local tracked = state.tracked[event.buf]
      if tracked and tracked.input and tracked.input.closing then
        update(event.buf, function(next)
          next.input = nil
          return next
        end)
        if vim.bo[event.buf].modified then
          mark(LOCAL, event.buf)
        end
      end
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
        if event.done and tracked.rewrite == rewrite then
          local completed = clone(rewrite)
          completed.after = vim.api.nvim_buf_get_changedtick(event.buf)
          tracked.rewrite = completed
        elseif not event.done then
          tracked.rewrite = rewrite
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
      mb.dispatch { kind = EVENTS.OBSERVE, buf = args.buf, base = snapshot.current(args.buf).text, track = true }
    end),
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedP" }, {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = async(function(args)
      mb.dispatch { kind = EVENTS.DIRTY, change = M.LOCAL, buf = args.buf }
    end),
  })

  vim.api.nvim_create_autocmd({ "TextChangedI" }, {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = async(function(args)
      mb.dispatch { kind = EVENTS.DIRTY, change = M.LOCAL, buf = args.buf, insert = true }
    end),
  })

  autocmd.insert_leave(
    {},
    async(function(args)
      mb.dispatch { kind = EVENTS.DIRTY, change = M.LOCAL, buf = args.buf, insert = false }
    end)
  )

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = async(function(args)
      mb.dispatch { kind = EVENTS.OBSERVE, buf = args.buf, base = snapshot.current(args.buf).text, track = false }
    end),
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = async(function(args)
      mb.dispatch { kind = EVENTS.DETACH, buf = args.buf }
    end),
  })

  vim.api.nvim_create_autocmd({ "FocusGained" }, {
    group = lib.group,
    callback = async(function()
      for buf, tracked in pairs(state.tracked) do
        if tracked.path then
          mb.dispatch { kind = EVENTS.DIRTY, change = M.REMOTE, buf = buf, watch = false }
        end
      end
    end),
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = "modifiable",
    callback = async(function()
      mb.dispatch { kind = EVENTS.DIRTY, change = M.REMOTE, buf = vim.api.nvim_get_current_buf(), watch = true }
    end),
  })

  autocmd.vim_enter(async(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        mb.dispatch { kind = EVENTS.OBSERVE, buf = buf, base = snapshot.current(buf).text, track = true }
      end
    end
  end))

  ---@param buf integer
  ---@param batch ChecktimeBatch
  ---@return ChecktimeBatch
  mb.latest = function(buf, batch)
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
      changedtick = vim.api.nvim_buf_get_changedtick(buf),
      input = tracked and tracked.input or nil,
    }
  end

  ---@return table<integer, ChecktimeBatch>
  mb.take = function()
    for buf, tracked in pairs(state.tracked) do
      if tracked.retry and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable then
        mb.dispatch { kind = EVENTS.DIRTY, change = M.REMOTE, buf = buf, watch = true }
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

  return mb
end

return M
