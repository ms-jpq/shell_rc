local async = require "goto.async"
local hunks = require "goto.checktime.hunks"
local mailbox = require "goto.checktime.stages.1-mailbox"
local resolve = require "goto.checktime.stages.2-resolve"
local snapshotter = require "goto.checktime.snapshotter"

local M = {}
local FLASH_SPAN = 1688

local ns = vim.api.nvim_create_namespace "goto.checktime"

---@class ChecktimeExecutor
---@field run fun(buf: integer, batch: ChecktimeBatch, instruction: ChecktimeInstruction)

---@param commit fun(change: ChecktimeCommit)
---@return ChecktimeExecutor
M.start = function(commit)
  ---@param buf integer
  ---@return ChecktimeAccepted?
  local publish = function(buf)
    local text = snapshotter.buffer(buf).text
    mailbox.writing(buf, true)
    local ok = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd [[silent! write! ++p]]
    end)
    if not ok or vim.bo[buf].modified then
      mailbox.writing(buf, false)
      return nil
    end

    local name = vim.api.nvim_buf_get_name(buf)
    local _, version = async.uv.fs_stat(name)
    async.scheduled()
    if not vim.api.nvim_buf_is_valid(buf) then
      return nil
    end
    mailbox.writing(buf, false)
    return { text = text, version = version }
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
      mailbox.rewriting(buf, function()
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        hunks.replace(buf, current, text, function(start, finish)
          vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
        end)
      end)
    end
    vim.bo[buf].modified = instruction.modified
  end

  ---@param buf integer
  ---@param batch ChecktimeBatch
  ---@param instruction ChecktimeInstruction
  local run = function(buf, batch, instruction)
    local current = function()
      return vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_changedtick(buf) == batch.changedtick
    end

    if not current() or snapshotter.insert_base(buf) then
      return
    elseif instruction.action == resolve.ACTIONS.RETRY then
      return
    elseif instruction.action == resolve.ACTIONS.NOOP then
      commit { buf = buf, batch = batch }
    elseif instruction.action == resolve.ACTIONS.RELOAD then
      if reload(buf) then
        commit { buf = buf, batch = batch, discard = true }
      end
    elseif instruction.action == resolve.ACTIONS.WRITE then
      ---@cast instruction ChecktimeWrite
      if snapshotter.unchanged(buf, instruction.version) and current() and not snapshotter.insert_base(buf) then
        local accepted = publish(buf)
        if accepted then
          commit { buf = buf, batch = batch, accepted = accepted }
        end
      end
    elseif instruction.action == resolve.ACTIONS.RECONCILE then
      ---@cast instruction ChecktimeReconcile
      local stale = instruction.save and not snapshotter.unchanged(buf, instruction.version)
      if not current() or snapshotter.insert_base(buf) then
        return
      end

      apply(buf, instruction)
      local accepted = { text = instruction.accepted, version = instruction.version } ---@type ChecktimeAccepted
      if stale then
        commit { buf = buf, accepted = accepted }
      elseif not instruction.save then
        commit { buf = buf, batch = batch, accepted = accepted }
      else
        local published = publish(buf)
        commit { buf = buf, accepted = published or accepted, batch = published and batch or nil }
      end
    else
      error(vim.inspect(instruction))
    end
  end

  return { run = run }
end

return M
