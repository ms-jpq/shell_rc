local async = require "goto.async"
local hunks = require "goto.checktime.hunks"
local mailbox = require "goto.checktime.stages.1-mailbox"
local plan = require "goto.checktime.stages.3-plan"
local snapshot = require "goto.checktime.snapshot"

local M = {}
local FLASH_SPAN = 1688
local EVENTS = mailbox.EVENTS

local ns = vim.api.nvim_create_namespace "goto.checktime"

---@class ChecktimeExecutor
---@field run fun(buf: integer, instruction: ChecktimeInstruction): ChecktimeOutcome

---@class ChecktimeOutcomes
M.OUTCOMES = {
  COMPLETE = "complete",
  DEFERRED = "deferred",
}

---@class ChecktimeComplete
---@field kind "complete"

---@class ChecktimeDeferred
---@field kind "deferred"

---@alias ChecktimeOutcome ChecktimeComplete|ChecktimeDeferred

---@class ChecktimeExecuteArgs
---@field dispatch fun(event: ChecktimeMailboxEvent)

---@param args ChecktimeExecuteArgs
---@return ChecktimeExecutor
M.start = function(args)
  ---@param buf integer
  ---@return boolean
  local write = function(buf)
    args.dispatch { kind = EVENTS.WRITING, buf = buf, value = true }
    local ok = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd [[silent! write! ++p]]
    end)
    local complete = ok and not vim.bo[buf].modified
    if not complete then
      args.dispatch { kind = EVENTS.WRITING, buf = buf, value = false }
    else
      local name = vim.api.nvim_buf_get_name(buf)
      local text = snapshot.current(buf).text
      local _, version = async.uv.fs_stat(name)
      async.scheduled()
      if not vim.api.nvim_buf_is_valid(buf) then
        return false
      end
      args.dispatch { kind = EVENTS.REMEMBER, buf = buf, base = text, version = version }
    end
    return complete
  end

  ---@param buf integer
  ---@return boolean
  local reload = function(buf)
    local ok = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd [[noautocmd silent! edit!]]
    end)
    return ok and not vim.bo[buf].modified
  end

  ---@param buf integer
  ---@param instruction ChecktimeReconcile
  local apply = function(buf, instruction)
    local current, text = assert(instruction.current), assert(instruction.text)
    if text ~= current.text then
      local rewrite = { before = vim.api.nvim_buf_get_changedtick(buf) } ---@type ChecktimeRewrite
      args.dispatch { kind = EVENTS.REWRITE, buf = buf, rewrite = rewrite, done = false }
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      ---@param start integer
      ---@param finish integer
      hunks.replace(buf, current, text, function(start, finish)
        vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
      end)
      args.dispatch { kind = EVENTS.REWRITE, buf = buf, rewrite = rewrite, done = true }
    end
    vim.bo[buf].modified = instruction.modified
  end

  ---@param buf integer
  ---@param instruction ChecktimeInstruction
  ---@return ChecktimeOutcome
  local run = function(buf, instruction)
    if instruction.action == plan.ACTIONS.RETRY then
      return { kind = M.OUTCOMES.DEFERRED }
    elseif instruction.action == plan.ACTIONS.RELOAD then
      local reloaded = reload(buf)
      if reloaded then
        args.dispatch { kind = EVENTS.DISCARD, buf = buf }
        return { kind = M.OUTCOMES.COMPLETE }
      end
      return { kind = M.OUTCOMES.DEFERRED }
    elseif instruction.action == plan.ACTIONS.WRITE then
      ---@cast instruction ChecktimeWrite
      local written = snapshot.unchanged(buf, instruction.version) and write(buf)
      if written then
        return { kind = M.OUTCOMES.COMPLETE }
      end
      return { kind = M.OUTCOMES.DEFERRED }
    elseif instruction.action == plan.ACTIONS.RECONCILE then
      ---@cast instruction ChecktimeReconcile
      if instruction.save and not snapshot.unchanged(buf, instruction.version) then
        args.dispatch { kind = EVENTS.REMEMBER, buf = buf, base = instruction.base, version = instruction.version }
        return { kind = M.OUTCOMES.DEFERRED }
      end
      apply(buf, instruction)
      args.dispatch { kind = EVENTS.REMEMBER, buf = buf, base = instruction.base, version = instruction.version }
      local written = not instruction.save or write(buf)
      if written then
        return { kind = M.OUTCOMES.COMPLETE }
      end
      return { kind = M.OUTCOMES.DEFERRED }
    elseif instruction.action == plan.ACTIONS.NOOP then
      return { kind = M.OUTCOMES.COMPLETE }
    else
      error(vim.inspect(instruction))
    end
  end

  return { run = run }
end

return M
