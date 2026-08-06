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
---@alias ChecktimeMailboxEventKind "change"|"command"|"detach"|"observe"|"refresh"
---@alias ChecktimeMailboxCommandKind "discard"|"finish"|"latest"|"remember"|"restore"|"rewrite"|"rewrite-done"|"take"|"writing"
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

---@class ChecktimeMailboxEvent
---@field kind ChecktimeMailboxEventKind
---@field buf integer
---@field command? ChecktimeMailboxCommandKind
---@field input? ChecktimeInputPhase
---@field base? string
---@field batch? ChecktimeBatch
---@field rewrite? ChecktimeRewrite
---@field value? boolean
---@field version? uv.fs_stat.result
---@field track? boolean
---@field watch? boolean

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
  CHANGE = "change",
  COMMAND = "command",
  DETACH = "detach",
  OBSERVE = "observe",
  REFRESH = "refresh",
}

---@class ChecktimeMailboxCommands
local COMMANDS = {
  DISCARD = "discard",
  FINISH = "finish",
  LATEST = "latest",
  REMEMBER = "remember",
  RESTORE = "restore",
  REWRITE = "rewrite",
  REWRITE_DONE = "rewrite-done",
  TAKE = "take",
  WRITING = "writing",
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

  local dispatch

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
          vim.schedule_wrap(function()
            for current, next in pairs(state.tracked) do
              if next.path == path then
                dispatch { kind = EVENTS.REFRESH, buf = current }
              end
            end
          end)
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

  dispatch = function(event)
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
        mark(M.REMOTE, event.buf)
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
        mark(M.REMOTE, event.buf)
      elseif read == snapshot.STATES.RECONCILE then
        update(event.buf, function(next)
          next.base, next.version = base, version
          return next
        end)
        if writing then
          mark(M.REMOTE, event.buf)
        end
      elseif read == snapshot.STATES.OPAQUE then
        update(event.buf, function(next)
          next.base, next.version = base, version
          return next
        end)
        if writing then
          mark(M.REMOTE, event.buf)
        end
      elseif read == snapshot.STATES.NONE then
        update(event.buf, function(next)
          next.base, next.version = base, version
          return next
        end)
        if writing then
          mark(M.REMOTE, event.buf)
        end
      else
        return assert(false, vim.inspect(read))
      end
    elseif event.kind == EVENTS.CHANGE then
      if event.input == INPUTS.CLOSING then
        update(event.buf, function(tracked)
          if tracked.input then
            tracked.input = { closing = true }
          end
          return tracked
        end)
        mark(M.LOCAL, event.buf)
      else
        local rewrite = state.tracked[event.buf] and state.tracked[event.buf].rewrite
        local changedtick = vim.api.nvim_buf_get_changedtick(event.buf)
        update(event.buf, function(tracked)
          tracked.rewrite = nil
          return tracked
        end)
        if rewrite and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after) then
          return
        elseif event.input == INPUTS.ACTIVE then
          update(event.buf, function(tracked)
            tracked.input = { closing = false }
            return tracked
          end)
        elseif event.input then
          return assert(false, vim.inspect(event))
        end
        mark(M.LOCAL, event.buf)
      end
    elseif event.kind == EVENTS.REFRESH then
      if event.watch then
        watch(event.buf, vim.bo[event.buf].modifiable and vim.api.nvim_buf_get_name(event.buf) or "")
      end
      if not event.watch or vim.bo[event.buf].modifiable then
        mark(M.REMOTE, event.buf)
      end
    elseif event.kind == EVENTS.DETACH then
      watch(event.buf, "")
      local tracked = clone(state.tracked)
      tracked[event.buf] = nil
      state = { entries = state.entries, observed = state.observed, tracked = tracked }
    elseif event.kind == EVENTS.COMMAND then
      local command = assert(event.command)
      if command == COMMANDS.DISCARD then
        update(event.buf, function(tracked)
          tracked.rewrite, tracked.input = nil, nil
          return tracked
        end)
      elseif command == COMMANDS.FINISH then
        local tracked = state.tracked[event.buf]
        if tracked and tracked.input and tracked.input.closing then
          update(event.buf, function(next)
            next.input = nil
            return next
          end)
          if vim.bo[event.buf].modified then
            mark(M.LOCAL, event.buf)
          end
        end
      elseif command == COMMANDS.LATEST then
        local batch = assert(event.batch)
        local changedtick = vim.api.nvim_buf_get_changedtick(event.buf)
        if changedtick ~= batch.changedtick then
          mark(M.LOCAL, event.buf)
        end
        local tracked = state.tracked[event.buf]
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
      elseif command == COMMANDS.REMEMBER then
        update(event.buf, function(tracked)
          tracked.base, tracked.version = event.base, event.version
          return tracked
        end)
      elseif command == COMMANDS.RESTORE then
        local batch = assert(event.batch)
        if vim.api.nvim_buf_get_changedtick(event.buf) ~= batch.changedtick then
          mark(M.LOCAL, event.buf)
        end
        for kind, order in pairs(batch.events) do
          mark(kind, event.buf, order)
        end
      elseif command == COMMANDS.REWRITE then
        local rewrite = { before = vim.api.nvim_buf_get_changedtick(event.buf) } ---@type ChecktimeRewrite
        update(event.buf, function(tracked)
          tracked.rewrite = rewrite
          return tracked
        end)
        return function()
          dispatch { kind = EVENTS.COMMAND, command = COMMANDS.REWRITE_DONE, buf = event.buf, rewrite = rewrite }
        end
      elseif command == COMMANDS.REWRITE_DONE then
        local rewrite = assert(event.rewrite)
        update(event.buf, function(tracked)
          if tracked.rewrite == rewrite then
            local completed = clone(rewrite)
            completed.after = vim.api.nvim_buf_get_changedtick(event.buf)
            tracked.rewrite = completed
          end
          return tracked
        end)
      elseif command == COMMANDS.TAKE then
        for buf, tracked in pairs(state.tracked) do
          if tracked.retry and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable then
            dispatch { kind = EVENTS.REFRESH, buf = buf, watch = true }
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
      elseif command == COMMANDS.WRITING then
        assert(event.value ~= nil)
        update(event.buf, function(tracked)
          tracked.writing = event.value
          return tracked
        end)
      else
        return assert(false, vim.inspect(event))
      end
    else
      return assert(false, vim.inspect(event))
    end
  end

  local emit = async(function(event)
    return dispatch(event)
  end)

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
      emit { kind = EVENTS.OBSERVE, buf = args.buf, base = snapshot.current(args.buf).text, track = true }
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedP" }, {
    group = lib.group,
    callback = function(args)
      emit { kind = EVENTS.CHANGE, buf = args.buf }
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChangedI" }, {
    group = lib.group,
    callback = function(args)
      emit { kind = EVENTS.CHANGE, buf = args.buf, input = INPUTS.ACTIVE }
    end,
  })

  autocmd.insert_leave({}, function(args)
    emit { kind = EVENTS.CHANGE, buf = args.buf, input = INPUTS.CLOSING }
  end)

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      emit { kind = EVENTS.OBSERVE, buf = args.buf, base = snapshot.current(args.buf).text }
    end,
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      emit { kind = EVENTS.DETACH, buf = args.buf }
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained" }, {
    group = lib.group,
    callback = function()
      for buf, tracked in pairs(state.tracked) do
        if tracked.path then
          emit { kind = EVENTS.REFRESH, buf = buf }
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = "modifiable",
    callback = function()
      emit { kind = EVENTS.REFRESH, buf = vim.api.nvim_get_current_buf(), watch = true }
    end,
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        emit { kind = EVENTS.OBSERVE, buf = buf, base = snapshot.current(buf).text, track = true }
      end
    end
  end)

  mb.discard = function(buf)
    dispatch { kind = EVENTS.COMMAND, command = COMMANDS.DISCARD, buf = buf }
  end
  mb.finish = function(buf)
    dispatch { kind = EVENTS.COMMAND, command = COMMANDS.FINISH, buf = buf }
  end
  mb.latest = function(buf, batch)
    local result = dispatch { kind = EVENTS.COMMAND, command = COMMANDS.LATEST, buf = buf, batch = batch }
    ---@cast result ChecktimeBatch
    return result
  end
  mb.remember = function(buf, base, version)
    dispatch { kind = EVENTS.COMMAND, command = COMMANDS.REMEMBER, buf = buf, base = base, version = version }
  end
  mb.restore = function(buf, batch)
    dispatch { kind = EVENTS.COMMAND, command = COMMANDS.RESTORE, buf = buf, batch = batch }
  end
  mb.rewrite = function(buf)
    local result = dispatch { kind = EVENTS.COMMAND, command = COMMANDS.REWRITE, buf = buf }
    ---@cast result fun()
    return result
  end
  mb.take = function()
    local result = dispatch { kind = EVENTS.COMMAND, command = COMMANDS.TAKE, buf = 0 }
    ---@cast result table<integer, ChecktimeBatch>
    return result
  end
  mb.writing = function(buf, value)
    dispatch { kind = EVENTS.COMMAND, command = COMMANDS.WRITING, buf = buf, value = value }
  end
  return mb
end

return M
