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
---@field run fun(buf: integer, batch: ChecktimeBatch, instruction: ChecktimeInstruction)

---@class ChecktimeExecuteArgs
---@field dispatch fun(event: ChecktimeMailboxEvent)

---@param args ChecktimeExecuteArgs
---@return ChecktimeExecutor
M.start = function(args)
  local dispatch = args.dispatch

  ---@param buf integer
  ---@param batch ChecktimeBatch
  local complete = function(buf, batch)
    dispatch { kind = EVENTS.CONSUME, buf = buf, batch = batch }
  end

  ---@param buf integer
  ---@param text string
  ---@param version? uv.fs_stat.result
  local accept = function(buf, text, version)
    dispatch { kind = EVENTS.ACCEPT, buf = buf, text = text, version = version }
  end

  ---@param buf integer
  ---@return boolean
  local publish = function(buf)
    dispatch { kind = EVENTS.WRITING, buf = buf, value = true }
    local ok = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd [[silent! write! ++p]]
    end)
    if not ok or vim.bo[buf].modified then
      dispatch { kind = EVENTS.WRITING, buf = buf, value = false }
      return false
    end

    local name = vim.api.nvim_buf_get_name(buf)
    local text = snapshot.current(buf).text
    local _, version = async.uv.fs_stat(name)
    async.scheduled()
    if not vim.api.nvim_buf_is_valid(buf) then
      return false
    end
    dispatch { kind = EVENTS.WRITING, buf = buf, value = false }
    accept(buf, text, version)
    return true
  end

  ---@param buf integer
  ---@return boolean
  local reload = function(buf)
    local ok = mailbox.reloading(buf, function()
      vim.api.nvim_buf_call(buf, function()
        vim.cmd [[silent edit!]]
      end)
    end)
    return ok and not vim.bo[buf].modified
  end

  ---@param buf integer
  ---@param instruction ChecktimeReconcile
  local apply = function(buf, instruction)
    local current, text = assert(instruction.current), assert(instruction.text)
    if text ~= current.text then
      local rewrite = { before = vim.api.nvim_buf_get_changedtick(buf) } ---@type ChecktimeRewrite
      dispatch { kind = EVENTS.REWRITE, buf = buf, rewrite = rewrite, done = false }
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      hunks.replace(buf, current, text, function(start, finish)
        vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
      end)
      dispatch { kind = EVENTS.REWRITE, buf = buf, rewrite = rewrite, done = true }
    end
    vim.bo[buf].modified = instruction.modified
  end

  ---@param buf integer
  ---@param batch ChecktimeBatch
  ---@param instruction ChecktimeInstruction
  local run = function(buf, batch, instruction)
    if instruction.action == plan.ACTIONS.RETRY then
      return
    elseif instruction.action == plan.ACTIONS.NOOP then
      complete(buf, batch)
    elseif instruction.action == plan.ACTIONS.RELOAD then
      if reload(buf) then
        dispatch { kind = EVENTS.DISCARD, buf = buf }
        complete(buf, batch)
      end
    elseif instruction.action == plan.ACTIONS.WRITE then
      ---@cast instruction ChecktimeWrite
      if snapshot.unchanged(buf, instruction.version) and publish(buf) then
        complete(buf, batch)
      end
    elseif instruction.action == plan.ACTIONS.RECONCILE then
      ---@cast instruction ChecktimeReconcile
      local stale = instruction.save and not snapshot.unchanged(buf, instruction.version)
      apply(buf, instruction)
      accept(buf, instruction.accepted, instruction.version)
      if stale then
        return
      elseif not instruction.save or publish(buf) then
        complete(buf, batch)
      end
    else
      error(vim.inspect(instruction))
    end
  end

  return { run = run }
end

return M
