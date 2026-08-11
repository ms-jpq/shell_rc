local M = {}

---@alias ChecktimeReducerActionKind "change"|"base"|"commit"

---@class ChecktimeReducerActions
M.ACTIONS = {
  CHANGE = "change",
  BASE = "base",
  COMMIT = "commit",
}

---@alias ChecktimeChange "remote"|"local"

---@class ChecktimeChanges
M.CHANGES = {
  LOCAL = "local",
  REMOTE = "remote",
}

---@class ChecktimeGeneration
---@field monotonic_ts integer
---@field sequential integer

---@alias ChecktimeEvents table<ChecktimeChange, ChecktimeGeneration>

---@class ChecktimeBase
---@field text? string
---@field version? uv.fs_stat.result

---@class ChecktimeFacts
---@field events ChecktimeEvents
---@field base? ChecktimeBase

---@class ChecktimeBatch
---@field events ChecktimeEvents
---@field changedtick integer
---@field base? ChecktimeBase

---@class ChecktimeChangeAction
---@field kind "change"
---@field change ChecktimeChange
---@field generation ChecktimeGeneration

---@class ChecktimeBaseAction
---@field kind "base"
---@field base ChecktimeBase

---@class ChecktimeCommitAction
---@field kind "commit"
---@field base? ChecktimeBase
---@field batch? ChecktimeBatch

---@alias ChecktimeReducerAction ChecktimeChangeAction|ChecktimeBaseAction|ChecktimeCommitAction

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

---@param facts ChecktimeFacts
---@param action ChecktimeReducerAction
---@return ChecktimeFacts
M.reduce = function(facts, action)
  local next = clone(facts)

  if action.kind == M.ACTIONS.CHANGE then
    next.events = clone(facts.events)
    next.events[action.change] = action.generation
    return next
  elseif action.kind == M.ACTIONS.BASE then
    next.base = action.base
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

---@param facts ChecktimeFacts
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

return M
