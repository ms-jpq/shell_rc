local async = require "goto.async"
local autocmd = require "goto.autocmd"
local feedback = require "goto.checktime.feedback"
local lib = require "goto.lib"
local reader = require "goto.checktime.reader"
local reducer = require "goto.checktime.reducer"
local snapshotter = require "goto.checktime.snapshotter"
local watcher = require "goto.checktime.watcher"

local M = {}

M.LOCAL = "local"

M.REMOTE = "remote"

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

---@class ChecktimeCommit
---@field buf integer
---@field accepted? ChecktimeAccepted
---@field batch? ChecktimeBatch
---@field discard? boolean

---@class ChecktimeCommitEvent: ChecktimeCommit
---@field kind "commit"

---@class ChecktimeSampled: ChecktimeSample
---@field kind "sampled"
---@field state ChecktimeReadState
---@field version? uv.fs_stat.result
---@field text? string

---@alias ChecktimeMailboxAction ChecktimeObserve|ChecktimeDirtyLocal|ChecktimeDirtyRemote|ChecktimeCommitEvent|ChecktimeSampled

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
  SAMPLED = "sampled",
}

local TRACKED = "__checktime_mailbox__"

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
  ---@param action ChecktimeReducerAction
  ---@return ChecktimeFacts
  local update = function(buf, action)
    local facts = reducer.reduce(vim.b[buf][TRACKED] or reducer.new(), action)
    vim.b[buf][TRACKED] = facts
    pending[buf] = next(facts.events) and true or nil
    return facts
  end

  ---@param buf integer
  ---@param text? string
  ---@param version? uv.fs_stat.result
  local accept = function(buf, text, version)
    update(buf, { kind = reducer.ACTIONS.ACCEPT, accepted = { text = text, version = version } })
  end

  ---@param kind ChecktimeChange
  ---@param buf integer
  ---@return ChecktimeGeneration
  local mark = function(kind, buf)
    local generation = gen()
    update(buf, { kind = reducer.ACTIONS.CHANGE, change = kind, generation = generation })
    return generation
  end

  local watches ---@type ChecktimeWatcher
  local reads ---@type ChecktimeReader
  local dispatch ---@type fun(action: ChecktimeMailboxAction)

  ---@param action ChecktimeMailboxAction
  dispatch = function(action)
    if not vim.api.nvim_buf_is_valid(action.buf) then
      return
    end
    if action.kind == EVENTS.COMMIT then
      update(action.buf, { kind = reducer.ACTIONS.COMMIT, accepted = action.accepted, batch = action.batch })

      if action.discard then
        feedback.discard(action.buf)
      end
      return
    elseif action.kind == EVENTS.DIRTY then
      if action.change == M.LOCAL then
        local rewrite = feedback.take_rewrite(action.buf)
        local changedtick = vim.api.nvim_buf_get_changedtick(action.buf)

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
      if not action.track and feedback.writes(action.buf) then
        return
      end

      if action.track then
        watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
        mark(M.REMOTE, action.buf)
        accept(action.buf, action.text)
      end

      feedback.discard(action.buf)
      reads.observe { buf = action.buf, source = action.text, track = action.track }
      return
    elseif action.kind == EVENTS.SAMPLED then
      if action.state == snapshotter.STATES.RETRY then
        mark(M.REMOTE, action.buf)
      elseif action.state == snapshotter.STATES.RECONCILE then
        accept(action.buf, action.track and action.source or action.text, action.version)
      elseif action.state == snapshotter.STATES.OPAQUE or action.state == snapshotter.STATES.MISSING then
        accept(action.buf, action.track and action.source or nil, action.version)
      else
        assert(false, vim.inspect(action))
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
    reloading = feedback.reloading,
  }

  reads = reader.start(function(sample, state, version, text)
    dispatch {
      kind = EVENTS.SAMPLED,
      buf = sample.buf,
      source = sample.source,
      track = sample.track,
      state = state,
      version = version,
      text = text,
    }
  end)

  ---@param buf integer
  ---@param before integer
  ---@return ChecktimeBatch?
  mb.latest = function(buf, before)
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    if changedtick ~= before then
      mark(M.LOCAL, buf)
    end
    local facts = vim.b[buf][TRACKED]
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
        local facts = vim.b[buf][TRACKED]
        if not facts or not next(facts.events) or not watches.has(buf) then
          pending[buf] = nil
        elseif
          not reads.active(buf)
          and not feedback.writes(buf)
          and not snapshotter.insert_base(buf)
          and not (
            vim.bo[buf].modified
            and facts.events[M.LOCAL]
            and vim.uv.hrtime() - facts.events[M.LOCAL].monotonic_ts < grace_ns
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
        if feedback.reloading(args.buf) then
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
        reads.drop(event.buf)
        if not feedback.reloading(event.buf) then
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
