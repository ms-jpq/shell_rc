local lib = require "goto.lib"
local reducer = require "goto.checktime.reducer"

local store = {}

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

---@class ChecktimeStoreCommit
---@field kind "commit"
---@field buf integer
---@field base? ChecktimeBase
---@field batch? ChecktimeBatch

---@alias ChecktimeStoreAction ChecktimeStoreChange|ChecktimeStoreBase|ChecktimeStoreCommit

---@class ChecktimeStoreStatus
---@field valid boolean
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
---@field latest fun(buf: integer, changedtick: integer): ChecktimeBatch?
---@field pending fun(): integer[]
---@field take fun(statuses: table<integer, ChecktimeStoreStatus>): table<integer, integer>

local FACTS = "__checktime_facts__"

---@param spec ChecktimeStoreConfig
---@return ChecktimeStore
store.start = function(spec)
  ---@diagnostic disable-next-line: missing-fields
  local state = {} ---@type ChecktimeStore
  local pending = {} ---@type table<integer, true>
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
    local facts = vim.b[action.buf][FACTS] or { events = {} }
    if action.kind == reducer.ACTIONS.CHANGE then
      facts = reducer.reduce(facts, { kind = action.kind, change = action.change, generation = generation() })
    elseif action.kind == reducer.ACTIONS.BASE then
      facts = reducer.reduce(facts, { kind = action.kind, base = action.base })
    elseif action.kind == reducer.ACTIONS.COMMIT then
      facts = reducer.reduce(facts, { kind = action.kind, base = action.base, batch = action.batch })
    else
      error(vim.inspect(action))
    end
    vim.b[action.buf][FACTS] = facts
    pending[action.buf] = next(facts.events) and true or nil
  end

  ---@param buf integer
  state.drop = function(buf)
    pending[buf] = nil
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf][FACTS] = nil
    end
  end

  ---@param buf integer
  ---@param changedtick integer
  ---@return ChecktimeBatch?
  state.latest = function(buf, changedtick)
    local facts = vim.b[buf][FACTS]
    return facts and reducer.batch(facts, changedtick) or nil
  end

  ---@return integer[]
  state.pending = function()
    local bufs = {}
    for buf in pairs(pending) do
      table.insert(bufs, buf)
    end
    return bufs
  end

  ---@param statuses table<integer, ChecktimeStoreStatus>
  ---@return table<integer, integer>
  state.take = function(statuses)
    local ready = {} ---@type table<integer, integer>
    local now = vim.uv.hrtime()

    for buf in pairs(pending) do
      local status = statuses[buf]
      if not status or not status.valid then
        state.drop(buf)
      elseif not status.watched then
        pending[buf] = nil
      else
        local facts = vim.b[buf][FACTS]
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

return store
