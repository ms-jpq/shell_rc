local reducer = {}

---@class ChecktimeReducerActions
---@field CHANGE "change"
---@field ACCEPT "accept"
---@field COMMIT "commit"
local ACTIONS = {
  CHANGE = "change",
  ACCEPT = "accept",
  COMMIT = "commit",
}

reducer.ACTIONS = ACTIONS

---@alias ChecktimeChange "remote"|"local"

---@class ChecktimeGeneration
---@field monotonic_ts integer
---@field sequential integer

---@alias ChecktimeEvents table<ChecktimeChange, ChecktimeGeneration>

---@class ChecktimeAccepted
---@field text? string
---@field version? uv.fs_stat.result

---@class ChecktimeFacts
---@field events ChecktimeEvents
---@field accepted? string
---@field version? uv.fs_stat.result

---@class ChecktimeBatch
---@field events ChecktimeEvents
---@field changedtick integer
---@field accepted? string
---@field version? uv.fs_stat.result

---@class ChecktimeChangeAction
---@field kind "change"
---@field change ChecktimeChange
---@field generation ChecktimeGeneration

---@class ChecktimeAcceptAction
---@field kind "accept"
---@field accepted ChecktimeAccepted

---@class ChecktimeCommitAction
---@field kind "commit"
---@field accepted? ChecktimeAccepted
---@field batch? ChecktimeBatch

---@alias ChecktimeReducerAction ChecktimeChangeAction|ChecktimeAcceptAction|ChecktimeCommitAction

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

---@return ChecktimeFacts
reducer.new = function()
  return { events = {} }
end

---@param facts ChecktimeFacts
---@param action ChecktimeReducerAction
---@return ChecktimeFacts
reducer.reduce = function(facts, action)
  local next = clone(facts)

  if action.kind == ACTIONS.CHANGE then
    next.events = clone(facts.events)
    next.events[action.change] = action.generation
    return next
  elseif action.kind == ACTIONS.ACCEPT then
    next.accepted, next.version = action.accepted.text, action.accepted.version
    return next
  elseif action.kind == ACTIONS.COMMIT then
    if action.accepted then
      next.accepted, next.version = action.accepted.text, action.accepted.version
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
reducer.batch = function(facts, changedtick)
  if not next(facts.events) then
    return nil
  end
  return {
    accepted = facts.accepted,
    version = facts.version,
    events = facts.events,
    changedtick = changedtick,
  }
end

return reducer
