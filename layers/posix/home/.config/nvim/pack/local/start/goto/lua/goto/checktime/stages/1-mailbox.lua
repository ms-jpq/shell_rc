local async = require "goto.async"
local autocmd = require "goto.autocmd"
local lib = require "goto.lib"
local snapshotter = require "goto.checktime.snapshotter"
local watcher = require "goto.checktime.watcher"

local M = {}

---@alias ChecktimeChange "remote"|"local"

---@type ChecktimeChange
M.LOCAL = "local"

---@type ChecktimeChange
M.REMOTE = "remote"

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

---@class ChecktimeGeneration
---@field monotonic_ts integer
---@field sequential integer

---@alias ChecktimeEvents table<ChecktimeChange, ChecktimeGeneration>

---@class ChecktimeRewrite
---@field before integer
---@field after? integer

---@class ChecktimeTracked
---@field events ChecktimeEvents
---@field generation ChecktimeGeneration
---@field guard integer
---@field accepted? string
---@field version? uv.fs_stat.result

---@class ChecktimeBatch
---@field events ChecktimeEvents
---@field changedtick integer
---@field accepted? string
---@field version? uv.fs_stat.result

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

---@class ChecktimeMailboxConfig
---@field grace_ms integer
---@field visible_interval integer
---@field hidden_interval integer

local EVENTS = {
  COMMIT = "commit",
  DIRTY = "dirty",
  OBSERVE = "observe",
}

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

local gen = (function()
  local n = 0
  ---@return ChecktimeGeneration
  return function()
    n = n + 1
    return { monotonic_ts = vim.uv.hrtime(), sequential = n }
  end
end)()

---@param spec ChecktimeMailboxConfig
---@return ChecktimeMailbox
M.start = function(spec)
  ---@diagnostic disable-next-line: missing-fields
  local mb = {} ---@type ChecktimeMailbox
  local pending = {} ---@type table<integer, true>
  local grace_ns = spec.grace_ms * lib.NANOSECONDS_PER_MILLISECOND

  ---@param buf integer
  ---@param fn fun(tracked: ChecktimeTracked): ChecktimeTracked
  ---@return ChecktimeTracked
  local update = function(buf, fn)
    local tracked = clone(vim.b[buf][TRACKED] or { events = {}, generation = gen(), guard = 0 })
    tracked = fn(tracked)
    vim.b[buf][TRACKED] = tracked
    pending[buf] = next(tracked.events) and true or nil
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
  ---@return ChecktimeGeneration
  local mark = function(kind, buf)
    local generation
    update(buf, function(tracked)
      generation = gen()
      local events = clone(tracked.events)
      events[kind] = generation
      tracked.events = events
      return tracked
    end)
    return generation
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
          local events = clone(tracked.events)
          for kind, generation in pairs(action.batch.events) do
            if events[kind] and events[kind].sequential == generation.sequential then
              events[kind] = nil
            end
          end
          tracked.events = events
        end
        return tracked
      end)

      if action.discard then
        vim.b[action.buf][REWRITE] = nil
      end
      return
    elseif action.kind == EVENTS.DIRTY then
      if action.change == M.LOCAL then
        local rewrite = vim.b[action.buf][REWRITE]
        local changedtick = vim.api.nvim_buf_get_changedtick(action.buf)
        vim.b[action.buf][REWRITE] = nil

        if rewrite and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after) then
          return
        end

        mark(M.LOCAL, action.buf)
      elseif action.change == M.REMOTE then
        if action.watch then
          watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
        end

        if not action.watch or vim.bo[action.buf].modifiable then
          mark(M.REMOTE, action.buf)
        end
      else
        assert(false, vim.inspect(action))
      end
      return
    elseif action.kind == EVENTS.OBSERVE then
      local tracked = vim.b[action.buf][TRACKED] or { events = {}, generation = gen(), guard = 0 }
      local generation = tracked.generation
      local writing = vim.b[action.buf][WRITING]
      if not action.track and writing then
        return
      end

      local source = action.text
      if action.track then
        watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
        generation = mark(M.REMOTE, action.buf)
      end
      update(action.buf, function(next)
        if action.track then
          next.accepted, next.version, next.generation = source, nil, generation
          next.guard = 1
        else
          next.guard = next.guard + 1
        end
        return next
      end)

      vim.b[action.buf][REWRITE] = nil

      local read, version, text = snapshotter.read(action.buf)
      if not vim.api.nvim_buf_is_valid(action.buf) then
        return
      end
      local current = vim.b[action.buf][TRACKED]
      if not current or current.generation.sequential ~= generation.sequential or current.guard == 0 then
        return
      end

      update(action.buf, function(next)
        assert(next.guard > 0)
        next.guard = next.guard - 1
        return next
      end)

      if read == snapshotter.STATES.RETRY then
        mark(M.REMOTE, action.buf)
      elseif read == snapshotter.STATES.RECONCILE then
        accept(action.buf, action.track and source or text, version)
      elseif read == snapshotter.STATES.OPAQUE or read == snapshotter.STATES.MISSING then
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
      dispatch { kind = EVENTS.DIRTY, change = M.REMOTE, buf = buf, watch = false }
    end,
    visible_interval = spec.visible_interval,
    hidden_interval = spec.hidden_interval,
    reloading = reloading,
  }

  ---@param buf integer
  ---@param before integer
  ---@return ChecktimeBatch?
  mb.latest = function(buf, before)
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    if changedtick ~= before then
      mark(M.LOCAL, buf)
    end
    local tracked = vim.b[buf][TRACKED]
    if not tracked or not next(tracked.events) then
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
    for buf in pairs(pending) do
      if not vim.api.nvim_buf_is_valid(buf) then
        pending[buf] = nil
      else
        local item = vim.b[buf][TRACKED]
        if not item or not next(item.events) or not watches.has(buf) then
          pending[buf] = nil
        elseif
          item.guard == 0
          and not vim.b[buf][WRITING]
          and not (
            vim.bo[buf].modified
            and item.events[M.LOCAL]
            and vim.uv.hrtime() - item.events[M.LOCAL].monotonic_ts < grace_ns
          )
        then
          ready[buf] = vim.api.nvim_buf_get_changedtick(buf)
        end
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
    snapshotter.track_insert(function(buf)
      dispatch { kind = EVENTS.DIRTY, change = M.REMOTE, buf = buf, watch = false }
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
        dispatch { kind = EVENTS.OBSERVE, buf = args.buf, text = snapshotter.buffer(args.buf).text, track = true }
      end),
    })

    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = function(args)
        watches.refresh(args.buf)
      end,
    })

    vim.api.nvim_create_autocmd("BufWinLeave", {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = function(args)
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(args.buf) and vim.api.nvim_buf_is_loaded(args.buf) then
            watches.refresh(args.buf)
          end
        end)
      end,
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = async(function(args)
        dispatch { kind = EVENTS.DIRTY, change = M.LOCAL, buf = args.buf, watch = false }
      end),
    })

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = async(function(args)
        dispatch { kind = EVENTS.OBSERVE, buf = args.buf, text = snapshotter.buffer(args.buf).text, track = false }
      end),
    })

    vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
      group = lib.group,
      callback = function(event)
        if not reloading(event.buf) then
          vim.b[event.buf][TRACKED] = nil
          pending[event.buf] = nil
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "OptionSet" }, {
      group = lib.group,
      pattern = "modifiable",
      callback = async(function()
        dispatch { kind = EVENTS.DIRTY, change = M.REMOTE, buf = vim.api.nvim_get_current_buf(), watch = true }
      end),
    })

    autocmd.vim_enter(function()
      for _, buf in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
          dispatch { kind = EVENTS.OBSERVE, buf = buf, text = snapshotter.buffer(buf).text, track = true }
        end
      end
    end)
  end

  return mb
end

return M
