local async = require "goto.async"
local autocmd = require "goto.autocmd"
local hunks = require "goto.fs_reconcile.hunks"
local lib = require "goto.lib"
local queue = require "goto.queue"
local util = require "goto.fs_reconcile.util"

---@class FsReconcileDocument
---@field changedtick integer
---@field base? FsReconcileBase
---@field local_at? integer
---@field remote_at? integer

---@class FsReconcilePendingWrite
---@field path string
---@field snapshot FsReconcileWriteSnapshot
---@field save_count integer

---@class FsReconcileLocalEvent
---@field type "local"
---@field at integer
---@field changedtick integer

---@class FsReconcileRemoteEvent
---@field type "remote"
---@field at integer

---@class FsReconcileRebindEvent
---@field type "rebind"
---@field at integer
---@field path string

---@class FsReconcileRetryEvent
---@field type "retry"
---@field sleep integer

---@class FsReconcileWriteEvent
---@field type "write"
---@field changedtick integer
---@field base FsReconcileBase
---@field path string

---@alias FsReconcileEvent FsReconcileLocalEvent|FsReconcileRebindEvent|FsReconcileRemoteEvent|FsReconcileRetryEvent|FsReconcileWriteEvent

---@class FsReconcileEvents
---@field LOCAL "local"
---@field REBIND "rebind"
---@field RETRY "retry"
---@field REMOTE "remote"
---@field WRITE "write"

---@class FsReconcileResolutions
---@field ADOPT "adopt"
---@field MERGE "merge"
---@field RETRY "retry"
---@field SAVE "save"
---@field SYNCED "synced"

---@class FsReconcileRetryResolution
---@field type "retry"
---@field sleep integer

---@class FsReconcileResolved
---@field type "synced"|"adopt"|"save"|"merge"

---@alias FsReconcileResolution FsReconcileRetryResolution|FsReconcileResolved

---@class FsReconcileChannel: QueueMpsc<FsReconcileEvent>
---@field retarget fun(path: string): boolean
---@field prepare_write fun(own: boolean)
---@field finish_write fun(): boolean

vim.opt.autoread = false
vim.opt.backup = false
vim.opt.writebackup = false

---@type FsReconcileEvents
local EVENTS = {
  LOCAL = "local",
  REBIND = "rebind",
  RETRY = "retry",
  REMOTE = "remote",
  WRITE = "write",
}

---@type FsReconcileResolutions
local RESOLUTIONS = {
  ADOPT = "adopt",
  MERGE = "merge",
  RETRY = "retry",
  SAVE = "save",
  SYNCED = "synced",
}

local TAG = "__fs_reconcile__"
local INTERVAL_MS = 99
local FLASH_SPAN = 200

local ns = vim.api.nvim_create_namespace "fs-reconcile"

local LOCAL_DELAY_MS = 3 * INTERVAL_MS
local REMOTE_DELAY_MS = 6 * INTERVAL_MS

---@return FsReconcileRemoteEvent
local remote = function()
  return { type = EVENTS.REMOTE, at = vim.uv.hrtime() }
end

---@param path string
---@return FsReconcileRebindEvent
local rebind = function(path)
  return { type = EVENTS.REBIND, at = vim.uv.hrtime(), path = path }
end

---@param sleep integer
---@return FsReconcileRetryEvent
local retry = function(sleep)
  return { type = EVENTS.RETRY, sleep = sleep }
end

---@param changedtick integer
---@return FsReconcileLocalEvent
local local_change = function(changedtick)
  return {
    type = EVENTS.LOCAL,
    at = vim.uv.hrtime(),
    changedtick = changedtick,
  }
end

---@param now integer
---@param at integer
---@param quiet integer
---@return integer
local remaining = function(now, at, quiet)
  return math.max(0, math.floor(quiet - lib.ns_to_ms(now - at)))
end

---@param buf integer
---@return FsReconcileChannel?
local get = function(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    return vim.b[buf][TAG]
  end
end

---@param buf integer
---@param chan FsReconcileChannel
---@return boolean
local attached = function(buf, chan)
  local current = get(buf)
  return current ~= nil and current.close == chan.close
end

---@param buf integer
---@param event FsReconcileEvent
local send = function(buf, event)
  local chan = get(buf)
  if chan then
    chan.send(event)
  end
end

---@param buf integer
---@param at integer
---@return FsReconcileDocument
local new_document = function(buf, at)
  return {
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    local_at = vim.bo[buf].modified and at or nil,
  }
end

---@param document FsReconcileDocument
---@param value FsReconcileSnapshot
---@param observed FsReconcileBase
---@param modified boolean
---@param now integer
---@return FsReconcileResolution
local resolve = function(document, value, observed, modified, now)
  local base = document.base
  local disk_unchanged = base ~= nil and util.same_buffer(base, observed)
  if disk_unchanged then
    base = observed
    document.base = observed
  end
  if base and not disk_unchanged and util.same_identity(base.version, observed.version) then
    local remote_at = document.remote_at or now
    local remote_sleep = remaining(now, remote_at, REMOTE_DELAY_MS)
    if remote_sleep > 0 then
      document.remote_at = remote_at
      return { type = RESOLUTIONS.RETRY, sleep = remote_sleep }
    end
  end
  document.remote_at = nil

  local buffer_is_observed = util.same_buffer(value, observed)
  local buffer_is_base = base ~= nil and util.same_buffer(value, base)

  if disk_unchanged and buffer_is_observed and not modified then
    return { type = RESOLUTIONS.SYNCED }
  elseif buffer_is_observed or (not base and not modified and observed.version) or buffer_is_base then
    return { type = RESOLUTIONS.ADOPT }
  elseif (not base and observed.version) or (base and not disk_unchanged) then
    return { type = RESOLUTIONS.MERGE }
  end
  return { type = RESOLUTIONS.SAVE }
end

local write = function()
  local fixendofline = vim.bo.fixendofline
  vim.bo.fixendofline = false
  local ok, err = pcall(function()
    vim.cmd [[noautocmd silent write! ++p]]
  end)
  vim.bo.fixendofline = fixendofline
  assert(ok, err)
end

---@param buf integer
---@param path string
---@param base FsReconcileBase
---@param guard fun(): boolean
---@return FsReconcileSnapshot?
---@return FsReconcileBase?
local save = function(buf, path, base, guard)
  local value, after
  local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
    vim.api.nvim_exec_autocmds({ "BufWritePre" }, { buffer = buf, data = { fs_reconcile = true } })
    if not guard() or not util.unchanged(path, base) then
      return
    end
    write()
    value = util.write_snapshot(buf)
    after = util.confirm_write(buf, path, value)
    if after == value then
      vim.bo[buf].modified = true
    end
    vim.api.nvim_exec_autocmds({ "BufWritePost" }, { buffer = buf, data = { fs_reconcile = true } })
  end)
  if not ok and value then
    vim.notify(err, vim.log.levels.ERROR)
  end
  return value, after
end

---@param buf integer
---@param chan FsReconcileChannel
---@param document FsReconcileDocument
---@param path string
---@param value FsReconcileSnapshot
---@param target FsReconcileBuffer
---@param observed FsReconcileBase
---@return boolean
local apply_observation = function(buf, chan, document, path, value, target, observed)
  local replacement
  if not util.same_buffer(value, target) then
    replacement = hunks.plan(value, target)
  end
  if
    not attached(buf, chan)
    or vim.api.nvim_buf_get_name(buf) ~= path
    or not vim.bo[buf].modifiable
    or not util.unchanged(path, observed)
    or value.changedtick ~= vim.api.nvim_buf_get_changedtick(buf)
  then
    chan.send(remote())
    return false
  end
  if replacement then
    hunks.apply(buf, replacement, function(start, finish)
      vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
    end)
  end
  vim.bo[buf].modified = not util.same_buffer(target, observed)
  document.base = observed
  document.changedtick = vim.api.nvim_buf_get_changedtick(buf)
  if vim.bo[buf].modified then
    chan.send(retry(0))
  end
  return true
end

---@param buf integer
---@param chan FsReconcileChannel
---@return fun()?
local start = function(buf, chan)
  local mpsc_close = chan.close
  local poller, path
  ---@type FsReconcilePendingWrite?
  local writing

  chan.finish_write = function()
    local before = writing
    if not before then
      return false
    elseif not attached(buf, chan) or before.path ~= vim.api.nvim_buf_get_name(buf) then
      writing = nil
      return false
    end

    local committed = vim.fn.undotree(buf).save_last > before.save_count
    if not committed and vim.fn.state "x" ~= "" then
      return true
    end
    writing = nil
    if committed then
      chan.send {
        type = EVENTS.WRITE,
        base = util.confirm_write(buf, before.path, before.snapshot),
        path = before.path,
        changedtick = vim.api.nvim_buf_get_changedtick(buf),
      }
    end
    return false
  end

  chan.prepare_write = function(own)
    chan.finish_write()
    writing = nil
    if not own then
      return
    end
    writing = {
      path = vim.api.nvim_buf_get_name(buf),
      snapshot = util.write_snapshot(buf),
      save_count = vim.fn.undotree(buf).save_last,
    }
    chan.send(retry(0))
  end

  chan.close = function()
    if poller then
      local current = poller
      poller = nil
      current.close()
    end
    if vim.api.nvim_buf_is_valid(buf) and attached(buf, chan) then
      vim.b[buf][TAG] = nil
    end
    mpsc_close()
  end

  chan.retarget = function(current)
    if poller and path == current then
      return true
    end
    if poller then
      poller.close()
      poller = nil
    end
    path = current
    poller = util.poller(path, INTERVAL_MS, function()
      chan.send(remote())
    end)
    if not poller then
      chan.close()
      return false
    end
    chan.send(rebind(current))
    return true
  end

  if not chan.retarget(vim.api.nvim_buf_get_name(buf)) then
    return
  end

  local changed = function(_, _, changedtick)
    if not attached(buf, chan) then
      return true
    end
    if writing and vim.fn.undotree(buf).save_last == writing.save_count then
      writing.snapshot = util.write_snapshot(buf)
    end
    chan.send(local_change(changedtick))
  end
  local listening = vim.api.nvim_buf_attach(buf, false, {
    on_changedtick = changed,
    on_lines = changed,
    on_detach = chan.close,
  })
  if not listening then
    chan.close()
    return
  end

  return chan.close
end

---@param buf integer
---@param chan FsReconcileChannel
---@param close fun()
local drive = function(buf, chan, close)
  ---@type FsReconcileDocument
  local document = new_document(buf, vim.uv.hrtime())
  local path = vim.api.nvim_buf_get_name(buf)
  local active = function()
    return attached(buf, chan) and vim.api.nvim_buf_get_name(buf) == path
  end
  local editable = function()
    return active() and vim.bo[buf].modifiable
  end

  lib.scope(function(defer)
    defer(close)
    for event in chan do
      local writing = chan.finish_write()
      if event.type == EVENTS.RETRY then
        local timed_out = chan.wait(event.sleep)
        if not timed_out then
          goto continue
        end
      elseif event.type == EVENTS.LOCAL then
        if event.changedtick > document.changedtick then
          document.local_at = event.at
          document.changedtick = event.changedtick
        end
      elseif event.type == EVENTS.REBIND then
        path = event.path
        document = new_document(buf, event.at)
      elseif event.type == EVENTS.WRITE then
        if event.path ~= path then
          goto continue
        end
        document.base = event.base
        document.changedtick = event.changedtick
        document.local_at = nil
      elseif event.type == EVENTS.REMOTE then
        document.remote_at = event.at
      else
        assert(false, event.type)
      end

      if not chan.empty() then
        goto continue
      elseif writing then
        chan.send(retry(INTERVAL_MS))
        goto continue
      end

      if vim.bo[buf].buftype ~= "" then
        break
      elseif not active() then
        goto continue
      elseif not vim.bo[buf].modifiable then
        chan.send(retry(REMOTE_DELAY_MS))
        goto continue
      end

      local value = util.buffer(buf)
      local observed, state = util.read_file(buf, path, document.base)
      local now = vim.uv.hrtime()
      if value.changedtick ~= document.changedtick then
        document.changedtick = value.changedtick
        document.local_at = vim.bo[buf].modified and now or nil
        chan.send(remote())
        goto continue
      elseif not observed then
        if state == util.READ.UNSTABLE then
          chan.send(retry(REMOTE_DELAY_MS))
        end
        goto continue
      end

      local resolution = resolve(document, value, observed, vim.bo[buf].modified, now)
      if resolution.type == RESOLUTIONS.SYNCED then
        goto continue
      elseif resolution.type == RESOLUTIONS.RETRY then
        chan.send(retry(resolution.sleep))
        goto continue
      elseif resolution.type == RESOLUTIONS.ADOPT then
        if apply_observation(buf, chan, document, path, value, observed, observed) then
          document.local_at = nil
        end
      elseif resolution.type == RESOLUTIONS.MERGE then
        local base = document.base or util.empty(buf)
        if not observed.version and base.version then
          goto continue
        end
        local target = hunks.merge(base, value, observed)
        apply_observation(buf, chan, document, path, value, target, observed)
      elseif resolution.type == RESOLUTIONS.SAVE then
        if vim.bo[buf].readonly then
          goto continue
        end
        local local_sleep = document.local_at and remaining(vim.uv.hrtime(), document.local_at, LOCAL_DELAY_MS) or 0
        if local_sleep > 0 then
          chan.send(retry(local_sleep))
          goto continue
        end
        local written, after = save(buf, path, document.base or util.empty(buf), editable)
        if not written then
          chan.send(retry(LOCAL_DELAY_MS))
          goto continue
        end
        document.changedtick = written.changedtick
        if active() then
          document.base = after
          document.local_at = nil
          chan.send(remote())
        end
      else
        assert(false, resolution.type)
      end
      ::continue::
    end
  end)
end

local detach = function(buf)
  local chan = get(buf)
  if chan then
    chan.close()
  end
end

local attach = function(buf)
  lib.report(function()
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
      return
    end
    local path = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype ~= "" or path == "" then
      detach(buf)
      return
    end

    local current = get(buf)
    if current then
      vim.bo[buf].autoread = not current.retarget(path)
      return
    end

    ---@type FsReconcileChannel
    local chan = queue.mpsc()
    local close = start(buf, chan)

    vim.bo[buf].autoread = close == nil
    if close then
      vim.b[buf][TAG] = chan
      drive(buf, chan, close)
    end
  end)
end

do
  vim.api.nvim_create_autocmd({ "QuitPre" }, {
    group = lib.group,
    command = [[silent! wall! ++p]],
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = async(function(args)
      if get(args.buf) then
        vim.v.fcs_choice = ""
        send(args.buf, remote())
      else
        vim.v.fcs_choice = "ask"
      end
    end),
  })

  vim.api.nvim_create_autocmd({ "BufUnload" }, {
    group = lib.group,
    callback = async(function(args)
      detach(args.buf)
    end),
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufFilePost", "BufEnter" }, {
    group = lib.group,
    callback = async(function(args)
      attach(args.buf)
    end),
  })

  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = lib.group,
    callback = function(args)
      local data = args.data or {}
      if data.fs_reconcile then
        return
      end
      local written = vim.fn.resolve(vim.fn.fnamemodify(args.file, ":p"))
      local name = vim.api.nvim_buf_get_name(args.buf)
      local path = vim.fn.resolve(name)
      local chan = get(args.buf)
      if chan then
        chan.prepare_write(written == path)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = { "buftype", "modifiable", "readonly" },
    callback = async(function(args)
      send(args.buf, remote())
      if args.match == "buftype" then
        if vim.bo[args.buf].buftype == "" then
          attach(args.buf)
        else
          detach(args.buf)
        end
      end
    end),
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      async(attach)(buf)
    end
  end, { group = lib.group })
end
