local hunks = require "goto.checktime.hunks"
local plan = require "goto.checktime.stages.3-plan"
local snapshot = require "goto.checktime.snapshot"

local M = {}

---@class ChecktimeExecutor
---@field run fun(buf: integer, instruction: ChecktimeInstruction): boolean

---@class ChecktimeExecuteIO
---@field apply fun(buf: integer, instruction: ChecktimeReconcile)
---@field reload fun(buf: integer): boolean
---@field unchanged fun(buf: integer, version: uv.fs_stat.result?): boolean
---@field write fun(buf: integer): boolean

---@param io ChecktimeExecuteIO
---@return ChecktimeExecutor
M.new = function(io)
  local run = function(buf, instruction)
    if instruction.action == plan.ACTIONS.RETRY then
      return false
    elseif instruction.action == plan.ACTIONS.RELOAD then
      return io.reload(buf)
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

---@param remember fun(buf: integer, base?: string, version?: uv.fs_stat.result)
---@return ChecktimeExecutor
M.start = function(remember)
  local ns = vim.api.nvim_create_namespace "goto.checktime"
  local flash_span = 1688

  ---@param buf integer
  ---@return boolean
  local write = function(buf)
    local ok = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd [[silent! write! ++p]]
    end)
    return ok and not vim.bo[buf].modified
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
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      hunks.replace(buf, current, text, function(start, finish)
        vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = flash_span })
      end)
    end
    remember(buf, instruction.base, instruction.version)
    vim.bo[buf].modified = instruction.modified
  end

  return M.new {
    apply = apply,
    reload = reload,
    unchanged = snapshot.unchanged,
    write = write,
  }
end

return M
