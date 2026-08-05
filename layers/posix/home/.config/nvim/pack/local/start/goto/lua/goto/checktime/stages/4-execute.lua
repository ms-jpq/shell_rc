local hunks = require "goto.checktime.hunks"
local plan = require "goto.checktime.stages.3-plan"
local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeExecutor
---@field run fun(buf: integer, instruction: ChecktimeInstruction): boolean

---@class ChecktimeExecuteIO
---@field apply fun(buf: integer, instruction: ChecktimeReconcile)
---@field discard fun(buf: integer)
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
      return false
    elseif instruction.action == plan.ACTIONS.RELOAD then
      local reloaded = io.reload(buf)
      if reloaded then
        io.discard(buf)
      end
      return reloaded
    elseif instruction.action == plan.ACTIONS.WRITE then
      return (instruction.force or io.unchanged(buf, instruction.version)) and io.write(buf)
    elseif instruction.action == plan.ACTIONS.RECONCILE then
      io.apply(buf, instruction)
      return not instruction.save or io.unchanged(buf, instruction.version) and io.write(buf)
    end
    return true
  end

  return { run = run }
end

---@param args ChecktimeExecuteArgs
---@return ChecktimeExecutor
M.start = function(args)
  local ns = vim.api.nvim_create_namespace "goto.checktime"
  local flash_span = 1688

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
        vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = flash_span })
      end)
      finish()
    end
    args.remember(buf, instruction.base, instruction.version)
    vim.bo[buf].modified = instruction.modified
  end

  return M.new {
    apply = apply,
    discard = args.discard,
    reload = reload,
    unchanged = snapshot.unchanged,
    write = write,
  }
end

return M
