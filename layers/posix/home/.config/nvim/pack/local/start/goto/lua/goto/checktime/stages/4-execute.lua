local hunks = require "goto.checktime.hunks"
local snapshot = require "goto.checktime.snapshot"

local M = {}
local FLASH_SPAN = 1688

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
    if instruction.action == "retry" then
      return false
    elseif instruction.action == "reload" then
      local reloaded = io.reload(buf)
      if reloaded then
        io.discard(buf)
      end
      return reloaded
    elseif instruction.action == "write" then
      return io.unchanged(buf, instruction.version) and io.write(buf)
    elseif instruction.action == "reconcile" then
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
        vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
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
