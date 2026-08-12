local async = require "goto.async"
local autocmd = require "goto.autocmd"
local lib = require "goto.lib"
local reader = require "goto.checktime.reader"
local reducer = require "goto.checktime.redux.reducer"
local session = require "goto.checktime.session"
local snapshotter = require "goto.checktime.snapshotter"
local store = require "goto.checktime.redux.store"

local M = {}

---@class ChecktimeCommitEvent: ChecktimeCommit
---@field kind "commit"

---@class ChecktimeLocal
---@field kind "local"
---@field buf integer

---@class ChecktimeRemote
---@field kind "remote"
---@field buf integer
---@field version? uv.fs_stat.result

---@class ChecktimeWatch
---@field kind "watch"
---@field buf integer

---@class ChecktimePostWrite
---@field kind "post-write"
---@field buf integer

---@alias ChecktimeIngressAction ChecktimeCommitEvent|ChecktimeLocal|ChecktimeRemote|ChecktimeWatch|ChecktimePostWrite|ChecktimeReaderObservation

---@class ChecktimeAutocmdArgs
---@field buf integer
---@field event string

---@class ChecktimeIngress
---@field commit fun(change: ChecktimeCommit)
---@field latest fun(buf: integer, changedtick: integer): ChecktimeBatch?
---@field take fun(): table<integer, integer>

---@class ChecktimeIngressConfig
---@field local_debounce_ms integer
---@field remote_quiet_ms integer
---@field visible_interval integer
---@field hidden_interval integer

---@class ChecktimeIngressEvents
local EVENTS = {
  COMMIT = "commit",
  LOCAL = "local",
  REMOTE = "remote",
  WATCH = "watch",
  POST_WRITE = "post-write",
}

---@param spec ChecktimeIngressConfig
---@return ChecktimeIngress
M.start = function(spec)
  ---@diagnostic disable-next-line: missing-fields
  local mb = {} ---@type ChecktimeIngress
  local state = store.start {
    local_debounce_ms = spec.local_debounce_ms,
    remote_quiet_ms = spec.remote_quiet_ms,
  }

  local watches ---@type ChecktimeWatcher
  local reads ---@type ChecktimeReader

  ---@param action ChecktimeIngressAction
  local post = function(action)
    if not vim.api.nvim_buf_is_valid(action.buf) then
      return
    elseif
      (action.kind == reader.OBSERVATIONS.RETRY or action.kind == reader.OBSERVATIONS.BASE)
      and not session.valid(action.session)
    then
      return
    elseif action.kind == EVENTS.COMMIT then
      ---@cast action ChecktimeCommitEvent
      state.dispatch { kind = reducer.ACTIONS.COMMIT, buf = action.buf, base = action.base, batch = action.batch }
      if action.discard then
        session.clear_rewrite(action.buf)
      end
    elseif action.kind == EVENTS.LOCAL then
      local changedtick = vim.api.nvim_buf_get_changedtick(action.buf)
      local echo = session.is_echo(action.buf, changedtick)
      session.take_rewrite(action.buf)
      if echo or not session.changed(action.buf, changedtick) then
        return
      end
      state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = action.buf, change = reducer.CHANGES.LOCAL }
    elseif action.kind == EVENTS.REMOTE then
      state.remote(action.buf, action.version)
    elseif action.kind == EVENTS.WATCH then
      watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
      if vim.bo[action.buf].modifiable then
        state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = action.buf, change = reducer.CHANGES.REMOTE }
      end
    elseif action.kind == EVENTS.POST_WRITE then
      if session.writing(action.buf) then
        return
      end
      session.clear_rewrite(action.buf)
      session.remember_checkpoint(action.buf, {
        changedtick = vim.api.nvim_buf_get_changedtick(action.buf),
        text = snapshotter.buffer(action.buf).text,
      })
      reads.read { buf = action.buf }
    elseif action.kind == reader.OBSERVATIONS.RETRY then
      ---@cast action ChecktimeReaderRetry
      local checkpoint = session.take_checkpoint(action.buf)
      if checkpoint and vim.api.nvim_buf_get_changedtick(action.buf) == checkpoint.changedtick then
        vim.bo[action.buf].modified = true
      end
      state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = action.buf, change = reducer.CHANGES.REMOTE }
    elseif action.kind == reader.OBSERVATIONS.BASE then
      ---@cast action ChecktimeReaderBase
      local checkpoint = session.take_checkpoint(action.buf)
      if
        checkpoint
        and (
          vim.api.nvim_buf_get_changedtick(action.buf) ~= checkpoint.changedtick
          or action.base.text ~= checkpoint.text
        )
      then
        vim.bo[action.buf].modified = true
        state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = action.buf, change = reducer.CHANGES.REMOTE }
      else
        state.dispatch { kind = reducer.ACTIONS.BASE, buf = action.buf, base = action.base }
        if action.observed and action.base.text ~= action.observed then
          state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = action.buf, change = reducer.CHANGES.REMOTE }
        end
      end
    else
      assert(false, vim.inspect(action))
    end
  end

  local attach = function(buf, refresh)
    local path = vim.bo[buf].modifiable and vim.api.nvim_buf_get_name(buf) or ""
    if not watches.attach(buf, path, refresh) then
      return
    end
    local text = snapshotter.buffer(buf).text
    state.dispatch { kind = reducer.ACTIONS.BASE, buf = buf, base = { text = text } }
    session.clear_rewrite(buf)
    session.take_checkpoint(buf)
    reads.read { buf = buf, initial = text }
  end

  watches = session.start_watch {
    changed = function(buf, version)
      post { kind = EVENTS.REMOTE, buf = buf, version = version }
    end,
    visible_interval = spec.visible_interval,
    hidden_interval = spec.hidden_interval,
  }

  reads = reader.start(post)

  ---@param buf integer
  ---@param before integer
  ---@return ChecktimeBatch?
  mb.latest = function(buf, before)
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    if changedtick ~= before and not session.is_echo(buf, changedtick) and session.changed(buf, changedtick) then
      state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = buf, change = reducer.CHANGES.LOCAL }
    end
    return state.latest(buf, changedtick)
  end

  ---@return table<integer, integer>
  mb.take = function()
    watches.retry()
    return state.take(function(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return nil
      end
      return {
        watched = watches.has(buf),
        reading = reads.active(buf),
        writing = session.writing(buf),
        insert_base = session.insert_base(buf) ~= nil,
        modified = vim.bo[buf].modified,
        changedtick = vim.api.nvim_buf_get_changedtick(buf),
      }
    end)
  end

  ---@param change ChecktimeCommit
  mb.commit = function(change)
    post {
      kind = EVENTS.COMMIT,
      buf = change.buf,
      base = change.base,
      batch = change.batch,
      discard = change.discard,
    }
  end

  autocmd.insert_mode({ group = lib.group }, function(event)
    session.begin_insert(event.buf, snapshotter.buffer(event.buf).text)
  end, function(event)
    if session.end_insert(event.buf) and not reads.active(event.buf) then
      post { kind = EVENTS.REMOTE, buf = event.buf, version = vim.uv.fs_stat(vim.api.nvim_buf_get_name(event.buf)) }
    end
  end)

  vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
    group = lib.group,
    command = [[silent! wall! ++p]],
  })

  vim.api.nvim_create_autocmd("FocusGained", {
    group = lib.group,
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if watches.has(buf) then
          post { kind = EVENTS.REMOTE, buf = buf }
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = async(function()
      vim.v.fcs_choice = ""
    end),
  })

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost", "BufFilePost" }, {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = async(function(args)
      if not session.reloading(args.buf) then
        attach(args.buf, args.event == "BufFilePost")
      end
    end),
  })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = function(args)
      watches.refresh(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = function(args)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(args.buf) and vim.api.nvim_buf_is_loaded(args.buf) then
          watches.refresh(args.buf)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = async(function(args)
      post { kind = EVENTS.LOCAL, buf = args.buf }
    end),
  })

  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = function(args)
      session.remember_written(args.buf, snapshotter.buffer(args.buf).text)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = async(function(args)
      async.scheduled()
      local before = session.take_written(args.buf)
      if before and before ~= snapshotter.buffer(args.buf).text then
        vim.bo[args.buf].modified = true
      end
      post { kind = EVENTS.POST_WRITE, buf = args.buf }
    end),
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(event)
      reads.drop(event.buf)
      if not session.reloading(event.buf) then
        state.drop(event.buf)
        watches.detach(event.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = "modifiable",
    callback = async(function()
      local buf = vim.api.nvim_get_current_buf()
      post { kind = EVENTS.WATCH, buf = buf }
    end),
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        attach(buf)
      end
    end
  end)

  return mb
end

return M
