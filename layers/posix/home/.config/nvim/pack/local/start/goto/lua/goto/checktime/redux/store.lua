local lib = require "goto.lib"
local reducer = require "goto.checktime.redux.reducer"
local session = require "goto.checktime.session"
local snapshotter = require "goto.checktime.snapshotter"

local M = {}

---@class ChecktimeCommit
---@field buf integer
---@field base? ChecktimeBase
---@field batch? ChecktimeBatch
---@field discard? boolean

---@class ChecktimeStoreChange
---@field kind "change"
---@field buf integer
---@field change ChecktimeChange

---@class ChecktimeStoreBase
---@field kind "base"
---@field buf integer
---@field base ChecktimeBase

---@class ChecktimeStoreForgetBase
---@field kind "forget-base"
---@field buf integer

---@class ChecktimeStoreCommit
---@field kind "commit"
---@field buf integer
---@field base? ChecktimeBase
---@field batch? ChecktimeBatch

---@alias ChecktimeStoreAction ChecktimeStoreChange|ChecktimeStoreBase|ChecktimeStoreForgetBase|ChecktimeStoreCommit

---@class ChecktimeStoreAdmission
---@field watched boolean
---@field reading boolean
---@field writing boolean
---@field insert_base boolean
---@field modified boolean
---@field changedtick integer

---@class ChecktimeStoreConfig
---@field local_debounce_ms integer
---@field remote_quiet_ms integer

---@class ChecktimeStore
---@field dispatch fun(action: ChecktimeStoreAction)
---@field drop fun(buf: integer)
---@field forget_base fun(buf: integer)
---@field latest fun(buf: integer, changedtick: integer): ChecktimeBatch?
---@field remote fun(buf: integer, version?: uv.fs_stat.result)
---@field take fun(admit: fun(buf: integer): ChecktimeStoreAdmission?): table<integer, integer>

---@param spec ChecktimeStoreConfig
---@return ChecktimeStore
M.start = function(spec)
  ---@diagnostic disable-next-line: missing-fields
  local state = {} ---@type ChecktimeStore
  local local_debounce_ns = spec.local_debounce_ms * lib.NANOSECONDS_PER_MILLISECOND
  local remote_quiet_ns = spec.remote_quiet_ms * lib.NANOSECONDS_PER_MILLISECOND
  local sequential = 0

  ---@return ChecktimeGeneration
  local generation = function()
    sequential = sequential + 1
    return { monotonic_ts = vim.uv.hrtime(), sequential = sequential }
  end

  ---@param action ChecktimeStoreAction
  state.dispatch = function(action)
    local facts = session.facts(action.buf) or { events = {} }
    if action.kind == reducer.ACTIONS.CHANGE then
      facts = reducer.reduce(facts, { kind = action.kind, change = action.change, generation = generation() })
    elseif action.kind == reducer.ACTIONS.BASE then
      facts = reducer.reduce(facts, { kind = action.kind, base = action.base })
    elseif action.kind == reducer.ACTIONS.FORGET_BASE then
      facts = reducer.reduce(facts, { kind = action.kind })
    elseif action.kind == reducer.ACTIONS.COMMIT then
      facts = reducer.reduce(facts, { kind = action.kind, base = action.base, batch = action.batch })
    else
      error(vim.inspect(action))
    end
    session.put_facts(action.buf, facts)
  end

  ---@param buf integer
  state.drop = function(buf)
    session.drop_facts(buf)
  end

  ---@param buf integer
  state.forget_base = function(buf)
    state.dispatch { kind = reducer.ACTIONS.FORGET_BASE, buf = buf }
  end

  ---@param buf integer
  ---@param changedtick integer
  ---@return ChecktimeBatch?
  state.latest = function(buf, changedtick)
    local facts = session.facts(buf)
    return facts and reducer.batch(facts, changedtick) or nil
  end

  ---@param buf integer
  ---@param version? uv.fs_stat.result
  state.remote = function(buf, version)
    local facts = session.facts(buf)
    if not (facts and snapshotter.same_version(facts.base and facts.base.version, version)) then
      state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = buf, change = reducer.CHANGES.REMOTE }
    end
  end

  ---@param admit fun(buf: integer): ChecktimeStoreAdmission?
  ---@return table<integer, integer>
  state.take = function(admit)
    local ready = {} ---@type table<integer, integer>
    local now = vim.uv.hrtime()

    for _, buf in ipairs(session.fact_buffers()) do
      local status = admit(buf)
      if not status then
        state.drop(buf)
      elseif status.watched then
        local facts = assert(session.facts(buf))
        local local_change, remote_change = facts.events[reducer.CHANGES.LOCAL], facts.events[reducer.CHANGES.REMOTE]
        local local_debounce = local_change and now - local_change.monotonic_ts < local_debounce_ns
        local remote_quiet = remote_change and now - remote_change.monotonic_ts < remote_quiet_ns
        if
          not status.reading
          and not status.writing
          and not status.insert_base
          and not (status.modified and local_debounce)
          and not remote_quiet
        then
          ready[buf] = status.changedtick
        end
      end
    end
    return ready
  end

  return state
end

return M
