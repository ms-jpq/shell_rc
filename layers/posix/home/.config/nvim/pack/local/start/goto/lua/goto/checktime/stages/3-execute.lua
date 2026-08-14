local async = require "goto.async"
local hunks = require "goto.checktime.hunks"
local resolve = require "goto.checktime.stages.2-resolve"
local session = require "goto.checktime.session"
local snapshotter = require "goto.checktime.snapshotter"

local M = {}
local FLASH_SPAN = 1688

local ns = vim.api.nvim_create_namespace "goto.checktime"

---@param buf integer
---@param version uv.fs_stat.result?
---@return boolean
local save = function(buf, version)
  local write = function()
    local id = vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = buf,
      once = true,
      callback = function()
        vim.api.nvim_exec_autocmds("BufWritePre", { buffer = buf })
        if not snapshotter.unchanged_now(buf, version) then
          return
        end
        vim.cmd [[noautocmd write! ++p]]
        vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf })
      end,
    })
    ---@diagnostic disable-next-line: param-type-mismatch
    local ok = pcall(vim.cmd, [[silent! write! ++p]])
    pcall(vim.api.nvim_del_autocmd, id)
    return ok
  end
  if buf == vim.api.nvim_get_current_buf() then
    return write()
  end

  local opened, win = pcall(vim.api.nvim_open_win, buf, false, {
    relative = "laststatus",
    anchor = "SE",
    row = 0,
    col = vim.o.columns - 1,
    width = 1,
    height = 1,
    style = "minimal",
    focusable = false,
    hide = true,
    noautocmd = true,
  })
  if not opened then
    return false
  end

  local ok, written = pcall(vim.api.nvim_win_call, win, write)
  if vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
  return ok and written
end

---@class ChecktimeExecutor
---@field run fun(buf: integer, batch: ChecktimeBatch, instruction: ChecktimeInstruction)

---@param commit fun(change: ChecktimeCommit)
---@return ChecktimeExecutor
M.start = function(commit)
  ---@param buf integer
  ---@param version uv.fs_stat.result?
  ---@return ChecktimeBase?
  local publish = function(buf, version)
    session.write(buf, true)
    local ok = save(buf, version)
    if not ok or vim.bo[buf].modified then
      session.write(buf, false)
      return nil
    end

    local text = snapshotter.buffer(buf).text
    local base, diverged = snapshotter.attest(buf, text)
    if not vim.api.nvim_buf_is_valid(buf) then
      return nil
    end
    if diverged then
      vim.bo[buf].modified = true
    end
    session.write(buf, false)
    return base
  end

  ---@param buf integer
  ---@return boolean
  local reload = function(buf)
    local ok = session.reload(buf, function()
      vim.api.nvim_buf_call(buf, function()
        vim.cmd [[silent edit!]]
      end)
    end)
    return ok and not vim.bo[buf].modified
  end

  ---@param buf integer
  ---@param instruction ChecktimeReconcile
  local apply = function(buf, instruction)
    local current, text = instruction.current, instruction.text
    if text ~= current.text then
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      if
        not hunks.replace(buf, current, text, function(start, finish)
          vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
        end)
      then
        return false
      end
    end
    vim.bo[buf].modified = instruction.modified
    return true
  end

  ---@param buf integer
  ---@param batch ChecktimeBatch
  ---@param instruction ChecktimeInstruction
  local run = function(buf, batch, instruction)
    local current = function()
      return vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_changedtick(buf) == batch.changedtick
    end

    if not current() or instruction.action == resolve.ACTIONS.RETRY then
      return
    end

    if instruction.action == resolve.ACTIONS.NOOP then
      commit { buf = buf, batch = batch }
      return
    end
    if instruction.action == resolve.ACTIONS.RELOAD then
      if session.insert_base(buf) then
        return
      end
      if reload(buf) then
        commit { buf = buf, batch = batch, discard = true }
      end
      return
    end
    if instruction.action == resolve.ACTIONS.WRITE then
      ---@cast instruction ChecktimeWrite
      if
        not snapshotter.unchanged(buf, instruction.base and instruction.base.version)
        or not current()
        or session.insert_base(buf)
      then
        return
      end

      local base = publish(buf, instruction.base and instruction.base.version)
      if base then
        commit { buf = buf, batch = batch, base = base }
      end
      return
    end
    if instruction.action ~= resolve.ACTIONS.RECONCILE then
      error(vim.inspect(instruction))
    end

    ---@cast instruction ChecktimeReconcile
    if not snapshotter.unchanged(buf, instruction.base.version) or not current() then
      return
    end

    if not apply(buf, instruction) then
      return
    end
    if instruction.create then
      local base = publish(buf, instruction.base.version)
      if base then
        commit { buf = buf, batch = batch, base = base }
      end
      return
    end
    local committed = batch
    if instruction.modified then
      committed = {
        base = batch.base,
        changedtick = batch.changedtick,
        events = { remote = batch.events.remote },
      }
    end
    commit { buf = buf, batch = committed, base = instruction.base }
  end

  return { run = run }
end

return M
