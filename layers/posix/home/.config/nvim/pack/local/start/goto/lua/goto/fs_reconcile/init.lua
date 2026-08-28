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

local mark = function(buf)
  return function(start, finish)
    vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
  end
end

local write = function()
  local fixendofline = vim.bo.fixendofline
  vim.bo.fixendofline = false
  local ok, err = pcall(function()
    vim.cmd [[noautocmd silent! write! ++p]]
  end)
  vim.bo.fixendofline = fixendofline
  assert(ok, err)
end

---@param buf integer
---@param path string
---@param base FsReconcileBase
---@param valid fun(): boolean
---@return FsReconcileSnapshot?
---@return FsReconcileBase?
local save = function(buf, path, base, valid)
  local ok, written = pcall(vim.api.nvim_buf_call, buf, function()
    vim.api.nvim_exec_autocmds({ "BufWritePre" }, { buffer = buf })
    if not valid() or not util.unchanged(path, base) then
      return false
    end
    write()
    vim.api.nvim_exec_autocmds({ "BufWritePost" }, { buffer = buf, data = { fs_reconcile = true } })
    return true
  end)
  if not ok or not written then
    return
  end
  local value = util.buffer(buf)
  local after = util.read_file(buf, path)
  if after and util.same_buffer(after, value) then
    return value, after
  end
  vim.bo[buf].modified = true
  return value
end

---@param buf integer
---@param value FsReconcileSnapshot
---@param target FsReconcileBuffer
---@param valid fun(): boolean
---@return boolean
local replace = function(buf, value, target, valid)
  local replacement
  if not util.same_buffer(value, target) then
    replacement = hunks.plan(value, target)
  end
  if not valid() or value.changedtick ~= vim.api.nvim_buf_get_changedtick(buf) then
    return false
  end
  if replacement then
    hunks.apply(buf, replacement, mark(buf))
  end
  return true
end

---@param current FsReconcileDocument
---@param changes table
---@return FsReconcileDocument
local next = function(current, changes)
  local copy = vim.tbl_extend("force", {}, current)
  ---@cast copy FsReconcileDocument
  for key, value in pairs(changes) do
    if value == vim.NIL then
      copy[key] = nil
    else
      copy[key] = value
    end
  end
  return copy
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

---@param buf integer
---@param chan FsReconcileChannel
---@return fun()?
local start = function(buf, chan)
  local mpsc_close = chan.close
  local poller, path

  chan.close = function()
    mpsc_close()
    if poller then
      poller.close()
    end
    if vim.api.nvim_buf_is_valid(buf) and attached(buf, chan) then
      vim.b[buf][TAG] = nil
    end
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

---@param document FsReconcileDocument
---@param value FsReconcileSnapshot
---@param observed FsReconcileBase
---@param modified boolean
---@param now integer
---@return FsReconcileDocument
---@return FsReconcileResolution
local resolve = function(document, value, observed, modified, now)
  local base = document.base
  local disk_unchanged = base ~= nil and util.same_observation(base.version, observed.version)
  if base and not disk_unchanged and util.same_identity(base.version, observed.version) then
    local remote_at = document.remote_at or now
    local remote_sleep = remaining(now, remote_at, REMOTE_DELAY_MS)
    if remote_sleep > 0 then
      return next(document, { remote_at = remote_at }), { type = RESOLUTIONS.RETRY, sleep = remote_sleep }
    end
  end
  document = next(document, { remote_at = vim.NIL })

  local buffer_is_observed = util.same_buffer(value, observed)
  local buffer_is_base = base ~= nil and util.same_buffer(value, base)

  if disk_unchanged and buffer_is_observed and buffer_is_base then
    return document, { type = RESOLUTIONS.SYNCED }
  elseif buffer_is_observed or (not base and not modified and observed.version) or buffer_is_base then
    return document, { type = RESOLUTIONS.ADOPT }
  elseif (not base and observed.version) or (base and not disk_unchanged) then
    return document, { type = RESOLUTIONS.MERGE }
  end
  return document, { type = RESOLUTIONS.SAVE }
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
  local valid = function()
    return active() and vim.bo[buf].modifiable
  end

  lib.scope(function(defer)
    defer(close)
    for event in chan do
      if event.type == EVENTS.RETRY then
        local timed_out = chan.wait(event.sleep)
        if not timed_out then
          goto continue
        end
      elseif event.type == EVENTS.LOCAL then
        if event.changedtick <= document.changedtick then
          goto continue
        end
        document = next(document, { local_at = event.at, changedtick = event.changedtick })
      elseif event.type == EVENTS.REBIND then
        path = event.path
        document = new_document(buf, event.at)
      elseif event.type == EVENTS.WRITE then
        document = next(document, {
          base = event.base,
          changedtick = event.changedtick,
          local_at = vim.NIL,
        })
      elseif event.type == EVENTS.REMOTE then
        document = next(document, { remote_at = event.at })
      else
        assert(false, event.type)
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
      local observed, state = util.read_file(buf, path)
      local now = vim.uv.hrtime()
      if value.changedtick ~= document.changedtick then
        document = next(document, {
          changedtick = value.changedtick,
          local_at = vim.bo[buf].modified and now or vim.NIL,
        })
        chan.send(remote())
        goto continue
      elseif not observed then
        if state == util.READ.UNSTABLE then
          chan.send(retry(REMOTE_DELAY_MS))
        end
        goto continue
      end
      local fresh = function()
        return valid() and util.unchanged(path, observed)
      end
      local resolution
      document, resolution = resolve(document, value, observed, vim.bo[buf].modified, now)

      if resolution.type == RESOLUTIONS.SYNCED then
        goto continue
      elseif resolution.type == RESOLUTIONS.RETRY then
        chan.send(retry(resolution.sleep))
        goto continue
      elseif resolution.type == RESOLUTIONS.ADOPT then
        if replace(buf, value, observed, fresh) then
          vim.bo[buf].modified = false
          document = next(document, {
            base = observed,
            changedtick = vim.api.nvim_buf_get_changedtick(buf),
            local_at = vim.NIL,
          })
        else
          chan.send(remote())
        end
      elseif resolution.type == RESOLUTIONS.MERGE then
        local base = document.base or util.empty(buf)
        if observed.version or not base.version then
          local target = hunks.merge(base, value, observed)
          if replace(buf, value, target, fresh) then
            vim.bo[buf].modified = not util.same_buffer(target, observed)
            local changedtick = vim.api.nvim_buf_get_changedtick(buf)
            document = next(document, { base = observed, changedtick = changedtick })
            if vim.bo[buf].modified then
              chan.send(retry(0))
            end
          else
            chan.send(remote())
          end
        end
      elseif resolution.type == RESOLUTIONS.SAVE then
        if vim.bo[buf].readonly then
          goto continue
        end
        local local_sleep = document.local_at and remaining(vim.uv.hrtime(), document.local_at, LOCAL_DELAY_MS) or 0
        if local_sleep > 0 then
          chan.send(retry(local_sleep))
          goto continue
        end
        local written, after = save(buf, path, document.base or util.empty(buf), valid)
        if not written then
          chan.send(retry(LOCAL_DELAY_MS))
          goto continue
        end
        document = next(document, { changedtick = written.changedtick })
        if valid() then
          if after then
            document = next(document, { base = after, local_at = vim.NIL })
          else
            chan.send(remote())
          end
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

---@param buf integer
local native_write = function(buf)
  local value = util.buffer(buf)
  local base = util.read_file(buf, vim.api.nvim_buf_get_name(buf))
  if base and util.same_buffer(base, value) then
    send(buf, {
      type = EVENTS.WRITE,
      changedtick = value.changedtick,
      base = base,
    })
  else
    send(buf, local_change(value.changedtick))
    send(buf, remote())
  end
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

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = async(function(args)
      local data = args.data or {}
      if data.fs_reconcile then
        return
      end
      local written = vim.uv.fs_realpath(args.file)
      local path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(args.buf))
      if written and written == path then
        native_write(args.buf)
        attach(args.buf)
      end
    end),
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
