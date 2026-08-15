local async = require "goto.async"
local autocmd = require "goto.autocmd"
local hunk_apply = require "goto.fs_reconcile.hunks.apply"
local hunks = require "goto.fs_reconcile.hunks"
local lib = require "goto.lib"
local queue = require "goto.queue"
local util = require "goto.fs_reconcile.util"

vim.opt.autoread = false
vim.opt.backup = false
vim.opt.writebackup = false

local TAG = "__fs_reconcile__"
local INTERVAL_MS = 99
local FLASH_SPAN = 200

local ns = vim.api.nvim_create_namespace "fs-reconcile"
local group = vim.api.nvim_create_augroup("lv_fs_reconcile", { clear = true })

local LOCAL_DELAY_MS = 3 * INTERVAL_MS
local REMOTE_DELAY_MS = 6 * INTERVAL_MS

---@class FsReconcileDocument
---@field changedtick integer
---@field base? FsReconcileBase
---@field inserting boolean
---@field local_at? integer
---@field remote_at? integer

---@class FsReconcileInsertEvent
---@field type "insert"
---@field inserting boolean

---@class FsReconcileLocalEvent
---@field type "local"
---@field at integer
---@field changedtick integer

---@class FsReconcileRemoteEvent
---@field type "remote"
---@field at integer

---@class FsReconcileRetryEvent
---@field type "retry"
---@field sleep integer

---@class FsReconcileWriteEvent
---@field type "write"
---@field changedtick integer
---@field base FsReconcileBase

---@alias FsReconcileEvent FsReconcileInsertEvent|FsReconcileLocalEvent|FsReconcileRemoteEvent|FsReconcileRetryEvent|FsReconcileWriteEvent

---@class FsReconcileEvents
---@field INSERT "insert"
---@field LOCAL "local"
---@field RETRY "retry"
---@field REMOTE "remote"
---@field WRITE "write"

---@type FsReconcileEvents
local EVENTS = {
  INSERT = "insert",
  LOCAL = "local",
  RETRY = "retry",
  REMOTE = "remote",
  WRITE = "write",
}

---@return FsReconcileRemoteEvent
local remote = function()
  return { type = EVENTS.REMOTE, at = vim.uv.hrtime() }
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

---@class FsReconcileResolutions
---@field ADOPT "adopt"
---@field INITIAL "initial"
---@field MERGE "merge"
---@field OPAQUE "opaque"
---@field REFRESH "refresh"
---@field RETRY "retry"
---@field SAVE "save"
---@field SYNCED "synced"

---@type FsReconcileResolutions
local RESOLUTIONS = {
  ADOPT = "adopt",
  INITIAL = "initial",
  MERGE = "merge",
  OPAQUE = "opaque",
  REFRESH = "refresh",
  RETRY = "retry",
  SAVE = "save",
  SYNCED = "synced",
}

---@class FsReconcileRefreshResolution
---@field type "refresh"

---@class FsReconcileRetryResolution
---@field type "retry"
---@field sleep integer

---@class FsReconcileOpaqueResolution
---@field type "opaque"

---@class FsReconcileResolved
---@field type "initial"|"synced"|"adopt"|"save"|"merge"
---@field value FsReconcileSnapshot
---@field observed FsReconcileBase

---@alias FsReconcileResolution FsReconcileRefreshResolution|FsReconcileRetryResolution|FsReconcileOpaqueResolution|FsReconcileResolved

---@alias FsReconcileChannel QueueMpsc<FsReconcileEvent>

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
    vim.cmd [[noautocmd silent! write! ++p]]
    vim.api.nvim_exec_autocmds({ "BufWritePost" }, { buffer = buf, data = { fs_reconcile = true } })
    return true
  end)
  if not ok or not written then
    return
  end
  local value = util.buffer(buf)
  local after = util.read_file(buf, path)
  if after and after.text == value.text then
    return value, after
  end
  vim.bo[buf].modified = true
  return value
end

---@param value FsReconcileSnapshot
---@param base FsReconcileBase
---@param observed FsReconcileBase
---@return string
local merge = function(value, base, observed)
  return hunks.merge(base.text, value.text, observed.text)
end

---@param buf integer
---@param value FsReconcileSnapshot
---@param text string
---@param valid fun(): boolean
---@return boolean
local replace = function(buf, value, text, valid)
  if value.text == text then
    return true
  end
  local replacement = hunk_apply.plan(value, text)
  if not valid() or value.changedtick ~= vim.api.nvim_buf_get_changedtick(buf) then
    return false
  end
  hunk_apply.run(buf, replacement, mark(buf))
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
---@param path string
---@param chan FsReconcileChannel
---@return fun()?
local start = function(buf, path, chan)
  local mpsc_close = chan.close
  local poller = util.poller(path, INTERVAL_MS, function()
    chan.send(remote())
  end)
  if not poller then
    return
  end

  local changed = async(function(_, _, changedtick)
    chan.send(local_change(changedtick))
  end)
  vim.api.nvim_buf_attach(buf, false, {
    on_changedtick = changed,
    on_lines = changed,
    on_detach = function()
      chan.close()
    end,
  })

  chan.close = function()
    mpsc_close()
    poller.close()
    if vim.api.nvim_buf_is_valid(buf) and attached(buf, chan) then
      vim.b[buf][TAG] = nil
    end
  end

  chan.send(remote())
  return chan.close
end

---@param document FsReconcileDocument
---@param value FsReconcileSnapshot
---@param observed FsReconcileBase?
---@param state "opaque"|"unstable"?
---@param modified boolean
---@param now integer
---@return FsReconcileDocument
---@return FsReconcileResolution
local resolve = function(document, value, observed, state, modified, now)
  if value.changedtick ~= document.changedtick then
    return next(document, {
      changedtick = value.changedtick,
      local_at = modified and now or vim.NIL,
    }),
      { type = RESOLUTIONS.REFRESH }
  elseif not observed then
    if state == util.READ.UNSTABLE then
      return document, { type = RESOLUTIONS.RETRY, sleep = REMOTE_DELAY_MS }
    end
    return document, { type = RESOLUTIONS.OPAQUE }
  end
  local base = document.base
  if base and not util.same_base(base, observed) and util.same_file(base.version, observed.version) then
    local remote_at = document.remote_at or now
    local remote_sleep = remaining(now, remote_at, REMOTE_DELAY_MS)
    if remote_sleep > 0 then
      return next(document, { remote_at = remote_at }), { type = RESOLUTIONS.RETRY, sleep = remote_sleep }
    end
  end
  document = next(document, { remote_at = vim.NIL })
  if document.inserting and document.local_at then
    local local_sleep = remaining(now, document.local_at, LOCAL_DELAY_MS)
    if local_sleep > 0 then
      return document, { type = RESOLUTIONS.RETRY, sleep = local_sleep }
    end
  end
  if not base then
    return document, { type = RESOLUTIONS.INITIAL, value = value, observed = observed }
  elseif value.text == base.text then
    return document,
      {
        type = util.same_base(base, observed) and RESOLUTIONS.SYNCED or RESOLUTIONS.ADOPT,
        value = value,
        observed = observed,
      }
  end
  return document,
    {
      type = util.same_base(base, observed) and RESOLUTIONS.SAVE or RESOLUTIONS.MERGE,
      value = value,
      observed = observed,
    }
end

---@param buf integer
---@param path string
---@param chan FsReconcileChannel
---@param close fun()
local drive = function(buf, path, chan, close)
  ---@type FsReconcileDocument
  local document = {
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    inserting = vim.api.nvim_get_current_buf() == buf and lib.is_insert(vim.api.nvim_get_mode().mode),
    local_at = vim.bo[buf].modified and vim.uv.hrtime() or nil,
  }
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
        local elapsed = chan.wait(event.sleep)
        if not elapsed then
          goto continue
        end
      elseif event.type == EVENTS.INSERT then
        document = next(document, { inserting = event.inserting })
      elseif event.type == EVENTS.LOCAL then
        if event.changedtick == document.changedtick then
          goto continue
        end
        document = next(document, { local_at = event.at, changedtick = event.changedtick })
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

      if not active() then
        goto continue
      elseif not vim.bo[buf].modifiable then
        chan.send(retry(REMOTE_DELAY_MS))
        goto continue
      end

      local value = util.buffer(buf)
      local observed, state = util.read_file(buf, path)
      local resolution
      document, resolution = resolve(document, value, observed, state, vim.bo[buf].modified, vim.uv.hrtime())

      if resolution.type == RESOLUTIONS.SYNCED then
        goto continue
      elseif resolution.type == RESOLUTIONS.OPAQUE then
        goto continue
      elseif resolution.type == RESOLUTIONS.RETRY then
        chan.send(retry(resolution.sleep))
        goto continue
      elseif resolution.type == RESOLUTIONS.REFRESH then
        chan.send(remote())
        goto continue
      elseif resolution.type == RESOLUTIONS.INITIAL then
        if
          vim.bo[buf].modified
          and resolution.observed.version
          and resolution.value.text ~= resolution.observed.text
        then
          local text = merge(resolution.value, { text = "" }, resolution.observed)
          if replace(buf, resolution.value, text, valid) then
            vim.bo[buf].modified = text ~= resolution.observed.text
            local changedtick = vim.api.nvim_buf_get_changedtick(buf)
            document = next(document, { base = resolution.observed, changedtick = changedtick })
          end
        else
          document = next(document, { base = resolution.observed })
        end
        if not document.base or resolution.value.text ~= resolution.observed.text then
          chan.send(retry(0))
        end
      elseif resolution.type == RESOLUTIONS.ADOPT then
        if replace(buf, resolution.value, resolution.observed.text, valid) then
          vim.bo[buf].modified = false
          document = next(document, {
            base = resolution.observed,
            changedtick = vim.api.nvim_buf_get_changedtick(buf),
            local_at = vim.NIL,
          })
        end
      elseif resolution.type == RESOLUTIONS.SAVE then
        if document.inserting or vim.bo[buf].readonly then
          goto continue
        end
        local local_sleep = document.local_at and remaining(vim.uv.hrtime(), document.local_at, LOCAL_DELAY_MS) or 0
        if local_sleep > 0 then
          chan.send(retry(local_sleep))
          goto continue
        end
        local written, after = save(buf, path, document.base, valid)
        if not written then
          goto continue
        end
        document = next(document, { changedtick = written.changedtick })
        if after then
          if valid() then
            document = next(document, { base = after, local_at = vim.NIL })
          end
        else
          if valid() then
            chan.send(remote())
          end
        end
      elseif resolution.type == RESOLUTIONS.MERGE then
        if resolution.observed.version or not document.base.version then
          local text = merge(resolution.value, document.base, resolution.observed)
          if replace(buf, resolution.value, text, valid) then
            vim.bo[buf].modified = text ~= resolution.observed.text
            local changedtick = vim.api.nvim_buf_get_changedtick(buf)
            document = next(document, { base = resolution.observed, changedtick = changedtick })
            if vim.bo[buf].modified then
              chan.send(retry(0))
            end
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
    local path = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype ~= "" or path == "" or get(buf) then
      return
    end

    ---@type FsReconcileChannel
    local chan = queue.mpsc()
    local close = start(buf, path, chan)

    vim.bo[buf].autoread = close == nil
    if close then
      vim.b[buf][TAG] = chan
      drive(buf, path, chan, close)
    end
  end)
end

---@param buf integer
local native_write = function(buf)
  local value = util.buffer(buf)
  local base = util.read_file(buf, vim.api.nvim_buf_get_name(buf))
  if base and base.text == value.text then
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
  vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
    group = group,
    command = [[silent! wall! ++p]],
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = group,
    callback = async(function(args)
      vim.v.fcs_choice = ""
      send(args.buf, remote())
    end),
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter" }, {
    group = group,
    callback = async(function(args)
      attach(args.buf)
    end),
  })

  vim.api.nvim_create_autocmd({ "BufFilePost" }, {
    group = group,
    callback = async(function(args)
      detach(args.buf)
      attach(args.buf)
    end),
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    callback = function(args)
      local data = args.data or {}
      if data.fs_reconcile then
        return
      end
      native_write(args.buf)
    end,
  })

  autocmd.insert_mode(
    { group = group },
    async(function(args)
      send(args.buf, { type = EVENTS.INSERT, inserting = true })
    end),
    async(function(args)
      send(args.buf, { type = EVENTS.INSERT, inserting = false })
    end)
  )

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = group,
    pattern = { "modifiable", "readonly" },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      send(buf, remote())
    end,
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        local current = buf
        async(function()
          attach(current)
        end)()
      end
    end
  end, { group = group })
end
