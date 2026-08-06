local async = require "goto.async"
local autocmd = require "goto.autocmd"
local lib = require "goto.lib"
local poll = require "goto.checktime.poll"
local snapshot = require "goto.checktime.snapshot"

local M = {}

---@alias ChecktimeEvent "remote"|"local"
---@alias ChecktimeEvents table<ChecktimeEvent, integer>

---@class ChecktimeInput
---@field closing boolean

---@class ChecktimeRewrite
---@field before integer
---@field after? integer

---@class ChecktimeTracked
---@field base? string
---@field version? uv.fs_stat.result
---@field events? ChecktimeEvents
---@field input? ChecktimeInput
---@field rewrite? ChecktimeRewrite
---@field writing? boolean
---@field initializing? boolean
---@field retry? string
---@field watcher? ChecktimePoller

---@class ChecktimeBatch
---@field base? string
---@field version? uv.fs_stat.result
---@field events ChecktimeEvents
---@field changedtick integer
---@field input? ChecktimeInput

---@class ChecktimeEventArgs
---@field buf integer

---@class ChecktimeMailbox
---@field rewrite fun(buf: integer): fun()
---@field discard fun(buf: integer)
---@field finish fun(buf: integer)
---@field remember fun(buf: integer, base?: string, version?: uv.fs_stat.result)
---@field latest fun(buf: integer, batch: ChecktimeBatch): ChecktimeBatch
---@field restore fun(buf: integer, batch: ChecktimeBatch)
---@field take fun(): table<integer, ChecktimeBatch>
---@field writing fun(buf: integer, value: boolean)

M.REMOTE, M.LOCAL = "remote", "local"

---@return ChecktimeMailbox
M.start = function()
  local entries = {} ---@type table<string, ChecktimePoller>
  local tracked = {} ---@type table<integer, ChecktimeTracked>
  local observed = 0
  ---@diagnostic disable-next-line: missing-fields
  local mailbox = {} ---@type ChecktimeMailbox

  ---@param buf integer
  ---@return ChecktimeTracked
  local state_for = function(buf)
    local state = tracked[buf] or {}
    tracked[buf] = state
    return state
  end

  ---@param kind ChecktimeEvent
  ---@param buf integer
  ---@param order? integer
  local mark = function(kind, buf, order)
    local state = state_for(buf)
    state.events = state.events or {}
    local previous = state.events[kind] or 0
    if order then
      observed = math.max(observed, order)
    else
      observed = observed + 1
      order = observed
    end
    state.events[kind] = math.max(previous, order)
  end

  ---@param buf integer
  ---@param before integer
  ---@return integer
  local sample = function(buf, before)
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    if changedtick ~= before then
      mark(M.LOCAL, buf)
    end
    return changedtick
  end

  ---@param buf integer
  local detach = function(buf)
    local state = tracked[buf]
    local watcher = state and state.watcher
    if state then
      state.retry = nil
    end
    if not watcher then
      return
    end
    watcher.bufs[buf] = nil
    state.watcher = nil
    if not next(watcher.bufs) then
      watcher.close()
      entries[watcher.path] = nil
    end
  end

  ---@param path string
  ---@return ChecktimePoller?
  local watcher_for = function(path)
    ---@type ChecktimePoller?
    local watcher = entries[path]
    if watcher then
      return watcher
    end
    local bufs = {}
    watcher = poll.start(
      path,
      bufs,
      vim.schedule_wrap(function()
        for buf in pairs(bufs) do
          mark(M.REMOTE, buf)
        end
      end)
    )
    if not watcher then
      return nil
    end
    entries[path] = watcher
    return watcher
  end

  ---@param buf integer
  ---@param path string
  local attach = function(buf, path)
    local state = state_for(buf)
    state.retry = path
    local watcher = watcher_for(path)
    if watcher then
      watcher.bufs[buf] = true
      state.watcher = watcher
      state.retry = nil
    end
  end

  mailbox.remember = function(buf, base, version)
    local state = state_for(buf)
    state.base, state.version = base, version
  end

  mailbox.writing = function(buf, value)
    state_for(buf).writing = value
  end

  mailbox.rewrite = function(buf)
    local rewrite = { before = vim.api.nvim_buf_get_changedtick(buf) } ---@type ChecktimeRewrite
    state_for(buf).rewrite = rewrite
    return function()
      rewrite.after = vim.api.nvim_buf_get_changedtick(buf)
    end
  end

  mailbox.discard = function(buf)
    local state = state_for(buf)
    state.rewrite, state.input = nil, nil
  end

  mailbox.finish = function(buf)
    local state = state_for(buf)
    if state.input and state.input.closing then
      state.input = nil
      if vim.bo[buf].modified then
        mark(M.LOCAL, buf)
      end
    end
  end

  local watch = function(buf)
    detach(buf)
    if vim.bo[buf].modifiable then
      local path = vim.api.nvim_buf_get_name(buf)
      if path ~= "" then
        attach(buf, path)
      end
    end
  end

  mailbox.latest = function(buf, batch)
    local changedtick = sample(buf, batch.changedtick)
    local state = tracked[buf]
    local pending = state and state.events or {}
    local local_order = math.max(batch.events[M.LOCAL] or 0, pending[M.LOCAL] or 0)
    local remote_order = math.max(batch.events[M.REMOTE] or 0, pending[M.REMOTE] or 0)
    local events = {} ---@type ChecktimeEvents
    if local_order > 0 then
      events[M.LOCAL] = local_order
    end
    if remote_order > 0 then
      events[M.REMOTE] = remote_order
    end
    return {
      base = batch.base,
      version = batch.version,
      events = events,
      changedtick = changedtick,
      input = state and state.input or nil,
    }
  end

  mailbox.restore = function(buf, batch)
    sample(buf, batch.changedtick)
    for kind, order in pairs(batch.events) do
      mark(kind, buf, order)
    end
  end

  mailbox.take = function()
    local batches = {} ---@type table<integer, ChecktimeBatch>
    for buf, state in pairs(tracked) do
      if state.retry and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable then
        attach(buf, state.retry)
        mark(M.REMOTE, buf)
      end
      local batch_events = state.events
      if not state.initializing and not state.writing and (state.watcher or state.retry) and batch_events then
        state.events = nil
        batches[buf] = {
          base = state.base,
          version = state.version,
          events = batch_events,
          changedtick = vim.api.nvim_buf_get_changedtick(buf),
          input = state.input,
        }
      end
    end
    return batches
  end

  ---@param args ChecktimeEventArgs
  ---@param seed? string
  local record = function(args, seed)
    local buf = args.buf
    local tracked_state = state_for(buf)
    local writing = tracked_state.writing
    local base = seed or (writing and snapshot.current(buf).text or nil)
    if not writing then
      mailbox.discard(buf)
    end
    local state, version, remote = snapshot.read(buf)
    tracked_state.initializing = nil
    tracked_state.writing = nil
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    if state == snapshot.STATES.RETRY then
      mark(M.REMOTE, buf)
      return
    elseif state == snapshot.STATES.RECONCILE then
      mailbox.remember(buf, base or remote, version)
    elseif state == snapshot.STATES.OPAQUE then
      mailbox.remember(buf, base, version)
    elseif state == snapshot.STATES.NONE then
      mailbox.remember(buf, base, version)
    else
      assert(false, vim.inspect(state))
    end
    if writing then
      mark(M.REMOTE, buf)
    end
  end

  ---@param args ChecktimeEventArgs
  local track = function(args)
    local buf = args.buf
    local tracked_state = state_for(buf)
    local seed = snapshot.current(buf).text
    tracked_state.initializing = true
    mailbox.remember(buf, seed)
    watch(buf)
    mark(M.REMOTE, buf)
    record(args, seed)
  end

  ---@param buf integer
  ---@return boolean
  local changed = function(buf)
    local state = state_for(buf)
    local rewrite = state.rewrite
    local changedtick = vim.api.nvim_buf_get_changedtick(buf)
    state.rewrite = nil
    if rewrite and changedtick ~= rewrite.before and (not rewrite.after or changedtick == rewrite.after) then
      return false
    end
    return true
  end

  vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
    group = lib.group,
    command = [[silent! wall! ++p]],
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = function()
      vim.v.fcs_choice = ""
    end,
  })

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost", "BufFilePost" }, {
    group = lib.group,
    callback = async(track),
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedP" }, {
    group = lib.group,
    callback = function(args)
      if changed(args.buf) then
        mark(M.LOCAL, args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChangedI" }, {
    group = lib.group,
    callback = function(args)
      if changed(args.buf) then
        local state = state_for(args.buf)
        local input = state.input or { closing = false }
        input.closing = false
        state.input = input
        mark(M.LOCAL, args.buf)
      end
    end,
  })

  autocmd.insert_leave({}, function(args)
    local state = state_for(args.buf)
    if state.input then
      state.input.closing = true
    end
    mark(M.LOCAL, args.buf)
  end)

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = async(record),
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      detach(args.buf)
      tracked[args.buf] = nil
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained" }, {
    group = lib.group,
    callback = function()
      for buf, state in pairs(tracked) do
        if state.watcher then
          mark(M.REMOTE, buf)
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = "modifiable",
    callback = function(args)
      local buf = vim.api.nvim_get_current_buf()
      watch(buf)
      if vim.bo[args.buf].modifiable then
        mark(M.REMOTE, buf)
      end
    end,
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        track { buf = buf }
      end
    end
  end)
  return mailbox
end

return M
