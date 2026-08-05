local async = require "goto.async"
local hunks = require "goto.checktime.hunks"
local plan = require "goto.checktime.stages.3-plan"
local snapshot = require "goto.checktime.snapshot"

local M = {}
local FLASH_SPAN = 1688

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

---@class ChecktimeExecuteIO
---@field apply fun(buf: integer, instruction: ChecktimeReconcile)
---@field discard fun(buf: integer)
---@field remember fun(buf: integer, base?: string, version?: uv.fs_stat.result)
---@field reload fun(buf: integer): boolean
---@field unchanged fun(buf: integer, version: uv.fs_stat.result?): boolean
---@field write fun(buf: integer): boolean

---@class ChecktimeExecuteArgs
---@field remember fun(buf: integer, base?: string, version?: uv.fs_stat.result)
---@field writing fun(buf: integer, value: boolean)
---@field discard fun(buf: integer)
---@field rewrite fun(buf: integer): fun()

---@param io ChecktimeExecuteIO
---@return ChecktimeExecutor
M.new = function(io)
  local run = function(buf, instruction)
    if instruction.action == plan.ACTIONS.RETRY then
      return { kind = M.OUTCOMES.DEFERRED }
    elseif instruction.action == plan.ACTIONS.RELOAD then
      local reloaded = io.reload(buf)
      if reloaded then
        io.discard(buf)
        return { kind = M.OUTCOMES.COMPLETE }
      end
      return { kind = M.OUTCOMES.DEFERRED }
    elseif instruction.action == plan.ACTIONS.WRITE then
      local written = io.unchanged(buf, instruction.version) and io.write(buf)
      return { kind = written and M.OUTCOMES.COMPLETE or M.OUTCOMES.DEFERRED }
    elseif instruction.action == plan.ACTIONS.RECONCILE then
      if instruction.save and not io.unchanged(buf, instruction.version) then
        io.remember(buf, instruction.base, instruction.version)
        return { kind = M.OUTCOMES.DEFERRED }
      end
      io.apply(buf, instruction)
      io.remember(buf, instruction.base, instruction.version)
      local written = not instruction.save or io.write(buf)
      return { kind = written and M.OUTCOMES.COMPLETE or M.OUTCOMES.DEFERRED }
    elseif instruction.action == plan.ACTIONS.NOOP then
      return { kind = M.OUTCOMES.COMPLETE }
    end
    assert(false, vim.inspect(instruction))
  end

  return { run = run }
end

---@param args ChecktimeExecuteArgs
---@return ChecktimeExecutor
M.start = function(args)
  local ns = vim.api.nvim_create_namespace "goto.checktime"

  ---@param buf integer
  ---@return boolean
  local write = function(buf)
    args.writing(buf, true)
    local ok = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd [[silent! write! ++p]]
    end)
    local complete = ok and not vim.bo[buf].modified
    if not complete then
      args.writing(buf, false)
    else
      local name = vim.api.nvim_buf_get_name(buf)
      local text = snapshot.current(buf).text
      local _, version = async.uv.fs_stat(name)
      async.scheduled()
      if not vim.api.nvim_buf_is_valid(buf) then
        return false
      end
      args.remember(buf, text, version)
    end
    return complete
  end

  ---@param buf integer
  ---@return boolean
  local reload = function(buf)
    local ok = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd [[silent! edit!]]
    end)
    return ok and not vim.bo[buf].modified
  end

  ---@param buf integer
  ---@param instruction ChecktimeReconcile
  local apply = function(buf, instruction)
    local current, text = assert(instruction.current), assert(instruction.text)
    if text ~= current.text then
      local finish = args.rewrite(buf)
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      hunks.replace(buf, current, text, function(start, finish)
        vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
      end)
      finish()
    end
    vim.bo[buf].modified = instruction.modified
  end

  return M.new {
    apply = apply,
    discard = args.discard,
    remember = args.remember,
    reload = reload,
    unchanged = snapshot.unchanged,
    write = write,
  }
end

return M
