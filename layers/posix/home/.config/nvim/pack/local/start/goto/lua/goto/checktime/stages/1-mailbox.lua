local async = require "goto.async"
local autocmd = require "goto.autocmd"
local feedback = require "goto.checktime.feedback"
local lib = require "goto.lib"
local reader = require "goto.checktime.reader"
local reducer = require "goto.checktime.reducer"
local snapshotter = require "goto.checktime.snapshotter"
local watcher = require "goto.checktime.watcher"

local mailbox = {}

---@class ChecktimeCommit
---@field buf integer
---@field base? ChecktimeBase
---@field batch? ChecktimeBatch
---@field discard? boolean

---@class ChecktimeCommitEvent: ChecktimeCommit
---@field kind "commit"

---@class ChecktimeLocal
---@field kind "local"
---@field buf integer

---@class ChecktimeRemote
---@field kind "remote"
---@field buf integer

---@class ChecktimeWatch
---@field kind "watch"
---@field buf integer

---@class ChecktimeLoad
---@field kind "load"
---@field buf integer
---@field base string

---@class ChecktimePostWrite
---@field kind "post-write"
---@field buf integer

---@class ChecktimeReadEvent: ChecktimeReadResult
---@field kind "read"

---@alias ChecktimeMailboxAction ChecktimeCommitEvent|ChecktimeLocal|ChecktimeRemote|ChecktimeWatch|ChecktimeLoad|ChecktimePostWrite|ChecktimeReadEvent

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

---@class ChecktimeMailboxEvents
local EVENTS = {
  COMMIT = "commit",
  LOCAL = "local",
  REMOTE = "remote",
  WATCH = "watch",
  LOAD = "load",
  POST_WRITE = "post-write",
  READ = "read",
}

local FACTS = "__checktime_facts__"

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
mailbox.start = function(spec)
  ---@diagnostic disable-next-line: missing-fields
  local mb = {} ---@type ChecktimeMailbox
  local pending = {} ---@type table<integer, true>
  local grace_ns = spec.grace_ms * lib.NANOSECONDS_PER_MILLISECOND

  ---@param buf integer
  ---@param action ChecktimeReducerAction
  local reduce = function(buf, action)
    local facts = reducer.reduce(vim.b[buf][FACTS] or { events = {} }, action)
    vim.b[buf][FACTS] = facts
    pending[buf] = next(facts.events) and true or nil
  end

  ---@param buf integer
  ---@param text? string
  ---@param version? uv.fs_stat.result
  local base = function(buf, text, version)
    reduce(buf, { kind = reducer.ACTIONS.BASE, base = { text = text, version = version } })
  end

  ---@param change ChecktimeChange
  ---@param buf integer
  local mark = function(change, buf)
    reduce(buf, { kind = reducer.ACTIONS.CHANGE, change = change, generation = gen() })
  end

  local watches ---@type ChecktimeWatcher
  local reads ---@type ChecktimeReader
  local dispatch ---@type fun(action: ChecktimeMailboxAction)

  ---@param action ChecktimeMailboxAction
  dispatch = function(action)
    if not vim.api.nvim_buf_is_valid(action.buf) then
      return
    elseif action.kind == EVENTS.COMMIT then
      ---@cast action ChecktimeCommitEvent
      reduce(action.buf, { kind = reducer.ACTIONS.COMMIT, base = action.base, batch = action.batch })
      if action.discard then
        feedback.clear_rewrite(action.buf)
      end
      return
    elseif action.kind == EVENTS.LOCAL then
      local rewrite = feedback.take_rewrite(action.buf)
      local changedtick = vim.api.nvim_buf_get_changedtick(action.buf)
      if rewrite and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after) then
        return
      end
      mark(reducer.CHANGES.LOCAL, action.buf)
      return
    elseif action.kind == EVENTS.REMOTE then
      mark(reducer.CHANGES.REMOTE, action.buf)
      return
    elseif action.kind == EVENTS.WATCH then
      watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
      if vim.bo[action.buf].modifiable then
        mark(reducer.CHANGES.REMOTE, action.buf)
      end
      return
    elseif action.kind == EVENTS.LOAD then
      ---@cast action ChecktimeLoad
      watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
      mark(reducer.CHANGES.REMOTE, action.buf)
      base(action.buf, action.base)
      feedback.clear_rewrite(action.buf)
      reads.read { buf = action.buf, base = action.base }
      return
    elseif action.kind == EVENTS.POST_WRITE then
      if feedback.writing(action.buf) then
        return
      end
      feedback.clear_rewrite(action.buf)
      reads.read { buf = action.buf }
      return
    elseif action.kind == EVENTS.READ then
      ---@cast action ChecktimeReadEvent
      if action.state == snapshotter.STATES.RETRY then
        mark(reducer.CHANGES.REMOTE, action.buf)
      elseif action.state == snapshotter.STATES.RECONCILE then
        base(action.buf, action.base or action.text, action.version)
      elseif action.state == snapshotter.STATES.OPAQUE or action.state == snapshotter.STATES.MISSING then
        base(action.buf, action.base, action.version)
      else
        assert(false, vim.inspect(action))
      end
      return
    else
      assert(false, vim.inspect(action))
    end
  end

  watches = watcher.start {
    changed = function(buf)
      dispatch { kind = EVENTS.REMOTE, buf = buf }
    end,
    visible_interval = spec.visible_interval,
    hidden_interval = spec.hidden_interval,
    reloading = feedback.reloading,
  }

  reads = reader.start(function(result)
    dispatch {
      kind = EVENTS.READ,
      buf = result.buf,
      base = result.base,
      state = result.state,
      version = result.version,
      text = result.text,
    }
  end)

  ---@param buf integer
  ---@param before integer
  ---@return ChecktimeBatch?
  mb.latest = function(buf, before)
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    if changedtick ~= before then
      mark(reducer.CHANGES.LOCAL, buf)
    end
    local facts = vim.b[buf][FACTS]
    return facts and reducer.batch(facts, changedtick) or nil
  end

  ---@return table<integer, integer>
  mb.take = function()
    watches.retry()
    local ready = {} ---@type table<integer, integer>
    for buf in pairs(pending) do
      if not vim.api.nvim_buf_is_valid(buf) then
        pending[buf] = nil
      else
        local facts = vim.b[buf][FACTS]
        if not facts or not next(facts.events) or not watches.has(buf) then
          pending[buf] = nil
        elseif
          not reads.active(buf)
          and not feedback.writing(buf)
          and not snapshotter.insert_base(buf)
          and not (
            vim.bo[buf].modified
            and facts.events[reducer.CHANGES.LOCAL]
            and vim.uv.hrtime() - facts.events[reducer.CHANGES.LOCAL].monotonic_ts < grace_ns
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
      base = change.base,
      batch = change.batch,
      discard = change.discard,
    }
  end

  do
    snapshotter.track_insert(function(buf)
      dispatch { kind = EVENTS.REMOTE, buf = buf }
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
        if not feedback.reloading(args.buf) then
          dispatch { kind = EVENTS.LOAD, buf = args.buf, base = snapshotter.buffer(args.buf).text }
        end
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
        dispatch { kind = EVENTS.LOCAL, buf = args.buf }
      end),
    })

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = lib.group,
      ---@param args ChecktimeAutocmdArgs
      callback = async(function(args)
        dispatch { kind = EVENTS.POST_WRITE, buf = args.buf }
      end),
    })

    vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
      group = lib.group,
      callback = function(event)
        reads.drop(event.buf)
        if not feedback.reloading(event.buf) then
          vim.b[event.buf][FACTS] = nil
          pending[event.buf] = nil
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "OptionSet" }, {
      group = lib.group,
      pattern = "modifiable",
      callback = async(function()
        dispatch { kind = EVENTS.WATCH, buf = vim.api.nvim_get_current_buf() }
      end),
    })

    autocmd.vim_enter(function()
      for _, buf in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
          dispatch { kind = EVENTS.LOAD, buf = buf, base = snapshotter.buffer(buf).text }
        end
      end
    end)
  end

  return mb
end

return mailbox
