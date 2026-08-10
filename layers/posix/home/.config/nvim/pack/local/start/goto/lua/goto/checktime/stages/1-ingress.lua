local async = require "goto.async"
local autocmd = require "goto.autocmd"
local feedback = require "goto.checktime.feedback"
local lib = require "goto.lib"
local reader = require "goto.checktime.reader"
local reducer = require "goto.checktime.reducer"
local snapshotter = require "goto.checktime.snapshotter"
local store = require "goto.checktime.store"
local watcher = require "goto.checktime.watcher"

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

---@class ChecktimeLoad
---@field kind "load"
---@field buf integer
---@field base string

---@class ChecktimePostWrite
---@field kind "post-write"
---@field buf integer

---@alias ChecktimeIngressAction ChecktimeCommitEvent|ChecktimeLocal|ChecktimeRemote|ChecktimeWatch|ChecktimeLoad|ChecktimePostWrite|ChecktimeReaderObservation

---@class ChecktimeAutocmdArgs
---@field buf integer

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
  LOAD = "load",
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
  local post ---@type fun(action: ChecktimeIngressAction)

  ---@param action ChecktimeIngressAction
  post = function(action)
    if not vim.api.nvim_buf_is_valid(action.buf) then
      return
    elseif action.kind == EVENTS.COMMIT then
      ---@cast action ChecktimeCommitEvent
      state.dispatch { kind = reducer.ACTIONS.COMMIT, buf = action.buf, base = action.base, batch = action.batch }
      if action.discard then
        feedback.clear_rewrite(action.buf)
      end
    elseif action.kind == EVENTS.LOCAL then
      local changedtick = vim.api.nvim_buf_get_changedtick(action.buf)
      local echo = feedback.is_echo(action.buf, changedtick)
      feedback.take_rewrite(action.buf)
      if echo then
        return
      end
      state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = action.buf, change = reducer.CHANGES.LOCAL }
    elseif action.kind == EVENTS.REMOTE then
      if not feedback.writing(action.buf) then
        state.remote(action.buf, action.version)
      end
    elseif action.kind == EVENTS.WATCH then
      watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
      if vim.bo[action.buf].modifiable then
        state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = action.buf, change = reducer.CHANGES.REMOTE }
      end
    elseif action.kind == EVENTS.LOAD then
      ---@cast action ChecktimeLoad
      watches.update(action.buf, vim.bo[action.buf].modifiable and vim.api.nvim_buf_get_name(action.buf) or "")
      state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = action.buf, change = reducer.CHANGES.REMOTE }
      state.dispatch { kind = reducer.ACTIONS.BASE, buf = action.buf, base = { text = action.base } }
      feedback.clear_rewrite(action.buf)
      reads.read { buf = action.buf, base = action.base }
    elseif action.kind == EVENTS.POST_WRITE then
      if feedback.writing(action.buf) then
        return
      end
      feedback.clear_rewrite(action.buf)
      reads.read { buf = action.buf }
    elseif action.kind == reader.OBSERVATIONS.RETRY then
      ---@cast action ChecktimeReaderRetry
      state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = action.buf, change = reducer.CHANGES.REMOTE }
    elseif action.kind == reader.OBSERVATIONS.BASE then
      ---@cast action ChecktimeReaderBase
      state.dispatch { kind = reducer.ACTIONS.BASE, buf = action.buf, base = action.base }
    else
      assert(false, vim.inspect(action))
    end
  end

  watches = watcher.start {
    changed = function(buf, version)
      post { kind = EVENTS.REMOTE, buf = buf, version = version }
    end,
    visible_interval = spec.visible_interval,
    hidden_interval = spec.hidden_interval,
    reloading = feedback.reloading,
  }

  reads = reader.start(post)

  ---@param buf integer
  ---@param before integer
  ---@return ChecktimeBatch?
  mb.latest = function(buf, before)
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    if changedtick ~= before and not feedback.is_echo(buf, changedtick) then
      state.dispatch { kind = reducer.ACTIONS.CHANGE, buf = buf, change = reducer.CHANGES.LOCAL }
    end
    return state.latest(buf, changedtick)
  end

  ---@return table<integer, integer>
  mb.take = function()
    watches.retry()
    local statuses = {} ---@type table<integer, ChecktimeStoreStatus>
    for _, buf in ipairs(state.pending()) do
      if vim.api.nvim_buf_is_valid(buf) then
        statuses[buf] = {
          valid = true,
          watched = watches.has(buf),
          reading = reads.active(buf),
          writing = feedback.writing(buf),
          insert_base = snapshotter.insert_base(buf) ~= nil,
          modified = vim.bo[buf].modified,
          changedtick = vim.api.nvim_buf_get_changedtick(buf),
        }
      end
    end
    return state.take(statuses)
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

  snapshotter.track_insert(function(buf)
    post { kind = EVENTS.REMOTE, buf = buf }
  end)

  vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
    group = lib.group,
    command = [[silent! wall! ++p]],
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
      if not feedback.reloading(args.buf) then
        post { kind = EVENTS.LOAD, buf = args.buf, base = snapshotter.buffer(args.buf).text }
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

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    ---@param args ChecktimeAutocmdArgs
    callback = async(function(args)
      post { kind = EVENTS.POST_WRITE, buf = args.buf }
    end),
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(event)
      reads.drop(event.buf)
      if not feedback.reloading(event.buf) then
        state.drop(event.buf)
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
        post { kind = EVENTS.LOAD, buf = buf, base = snapshotter.buffer(buf).text }
      end
    end
  end)

  return mb
end

return M
