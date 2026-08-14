local lib = require "goto.lib"
local session = require "goto.checktime.session"
local snapshotter = require "goto.checktime.snapshotter"

local M = {}

---@class ChecktimeMailboxActions
M.ACTIONS = {
  CHANGE = "change",
  BASE = "base",
  FORGET_BASE = "forget-base",
  COMMIT = "commit",
}

---@class ChecktimeChanges
M.CHANGES = {
  LOCAL = "local",
  REMOTE = "remote",
}

---@class ChecktimeGeneration
---@field monotonic_ts integer
---@field sequential integer

---@alias ChecktimeChange "remote"|"local"
---@alias ChecktimeEvents table<ChecktimeChange, ChecktimeGeneration>

---@class ChecktimeBase
---@field text? string
---@field version? uv.fs_stat.result

---@class ChecktimeMailboxFacts
---@field events ChecktimeEvents
---@field base? ChecktimeBase

---@class ChecktimeBatch
---@field events ChecktimeEvents
---@field changedtick integer
---@field base? ChecktimeBase

---@class ChecktimeCommit
---@field buf integer
---@field base? ChecktimeBase
---@field batch? ChecktimeBatch
---@field discard? boolean

---@class ChecktimeMailboxChange
---@field kind "change"
---@field change ChecktimeChange
---@field generation ChecktimeGeneration

---@class ChecktimeMailboxBase
---@field kind "base"
---@field base ChecktimeBase

---@class ChecktimeMailboxForgetBase
---@field kind "forget-base"

---@class ChecktimeMailboxCommit
---@field kind "commit"
---@field base? ChecktimeBase
---@field batch? ChecktimeBatch

---@alias ChecktimeMailboxTransition ChecktimeMailboxChange|ChecktimeMailboxBase|ChecktimeMailboxForgetBase|ChecktimeMailboxCommit

---@class ChecktimeMailboxDispatchChange
---@field kind "change"
---@field buf integer
---@field change ChecktimeChange

---@class ChecktimeMailboxDispatchBase
---@field kind "base"
---@field buf integer
---@field base ChecktimeBase

---@class ChecktimeMailboxDispatchForgetBase
---@field kind "forget-base"
---@field buf integer

---@class ChecktimeMailboxDispatchCommit
---@field kind "commit"
---@field buf integer
---@field base? ChecktimeBase
---@field batch? ChecktimeBatch

---@alias ChecktimeMailboxAction ChecktimeMailboxDispatchChange|ChecktimeMailboxDispatchBase|ChecktimeMailboxDispatchForgetBase|ChecktimeMailboxDispatchCommit

---@class ChecktimeMailboxAdmission
---@field watched boolean
---@field reading boolean
---@field writing boolean
---@field insert_base boolean
---@field modified boolean
---@field changedtick integer

---@class ChecktimeMailboxConfig
---@field local_debounce_ms integer
---@field remote_quiet_ms integer

---@class ChecktimeMailbox
---@field dispatch fun(action: ChecktimeMailboxAction)
---@field drop fun(buf: integer)
---@field forget_base fun(buf: integer)
---@field latest fun(buf: integer, changedtick: integer): ChecktimeBatch?
---@field remote fun(buf: integer, version?: uv.fs_stat.result)
---@field take fun(admit: fun(buf: integer): ChecktimeMailboxAdmission?): table<integer, integer>

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

---@param facts ChecktimeMailboxFacts
---@param action ChecktimeMailboxTransition
---@return ChecktimeMailboxFacts
M.reduce = function(facts, action)
  local next = clone(facts)

  if action.kind == M.ACTIONS.CHANGE then
    next.events = clone(facts.events)
    next.events[action.change] = action.generation
    return next
  elseif action.kind == M.ACTIONS.BASE then
    next.base = action.base
    return next
  elseif action.kind == M.ACTIONS.FORGET_BASE then
    next.base = nil
    return next
  elseif action.kind == M.ACTIONS.COMMIT then
    if action.base then
      next.base = action.base
    end
    if action.batch then
      next.events = clone(facts.events)
      for kind, generation in pairs(action.batch.events) do
        if next.events[kind] and next.events[kind].sequential == generation.sequential then
          next.events[kind] = nil
        end
      end
    end
    return next
  else
    error(vim.inspect(action))
  end
end

---@param facts ChecktimeMailboxFacts
---@param changedtick integer
---@return ChecktimeBatch?
M.batch = function(facts, changedtick)
  if not next(facts.events) then
    return nil
  end
  return {
    base = facts.base,
    events = facts.events,
    changedtick = changedtick,
  }
end

---@param spec ChecktimeMailboxConfig
---@return ChecktimeMailbox
M.start = function(spec)
  ---@diagnostic disable-next-line: missing-fields
  local mailbox = {} ---@type ChecktimeMailbox
  local local_debounce_ns = lib.ms_to_ns(spec.local_debounce_ms)
  local remote_quiet_ns = lib.ms_to_ns(spec.remote_quiet_ms)
  local sequential = 0

  ---@return ChecktimeGeneration
  local generation = function()
    sequential = sequential + 1
    return { monotonic_ts = vim.uv.hrtime(), sequential = sequential }
  end

  ---@param action ChecktimeMailboxAction
  mailbox.dispatch = function(action)
    local facts = session.mailbox(action.buf) or { events = {} }
    if action.kind == M.ACTIONS.CHANGE then
      facts = M.reduce(facts, { kind = action.kind, change = action.change, generation = generation() })
    elseif action.kind == M.ACTIONS.BASE then
      facts = M.reduce(facts, { kind = action.kind, base = action.base })
    elseif action.kind == M.ACTIONS.FORGET_BASE then
      facts = M.reduce(facts, { kind = action.kind })
    elseif action.kind == M.ACTIONS.COMMIT then
      facts = M.reduce(facts, { kind = action.kind, base = action.base, batch = action.batch })
    else
      error(vim.inspect(action))
    end
    session.put_mailbox(action.buf, facts)
  end

  ---@param buf integer
  mailbox.drop = function(buf)
    session.drop_mailbox(buf)
  end

  ---@param buf integer
  mailbox.forget_base = function(buf)
    mailbox.dispatch { kind = M.ACTIONS.FORGET_BASE, buf = buf }
  end

  ---@param buf integer
  ---@param changedtick integer
  ---@return ChecktimeBatch?
  mailbox.latest = function(buf, changedtick)
    local facts = session.mailbox(buf)
    return facts and M.batch(facts, changedtick) or nil
  end

  ---@param buf integer
  ---@param version? uv.fs_stat.result
  mailbox.remote = function(buf, version)
    local facts = session.mailbox(buf)
    if not (facts and snapshotter.same_version(facts.base and facts.base.version, version)) then
      mailbox.dispatch { kind = M.ACTIONS.CHANGE, buf = buf, change = M.CHANGES.REMOTE }
    end
  end

  ---@param admit fun(buf: integer): ChecktimeMailboxAdmission?
  ---@return table<integer, integer>
  mailbox.take = function(admit)
    local ready = {} ---@type table<integer, integer>
    local now = vim.uv.hrtime()

    for _, buf in ipairs(session.mailbox_buffers()) do
      local status = admit(buf)
      if not status then
        mailbox.drop(buf)
      elseif status.watched then
        local facts = assert(session.mailbox(buf))
        local local_change, remote_change = facts.events[M.CHANGES.LOCAL], facts.events[M.CHANGES.REMOTE]
        local local_debounce = local_change and now - local_change.monotonic_ts < local_debounce_ns
        local remote_quiet = remote_change and now - remote_change.monotonic_ts < remote_quiet_ns
        if
          not status.reading
          and not status.writing
          and (not status.insert_base or remote_change ~= nil)
          and not (status.modified and local_debounce)
          and not remote_quiet
        then
          ready[buf] = status.changedtick
        end
      end
    end
    return ready
  end

  return mailbox
end

return M
