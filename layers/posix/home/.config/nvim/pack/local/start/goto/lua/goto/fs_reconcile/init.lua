local async = require "goto.async"
local autocmd = require "goto.autocmd"
local hunk_apply = require "goto.fs_reconcile.hunks.apply"
local hunks = require "goto.fs_reconcile.hunks"
local lib = require "goto.lib"
local util = require "goto.fs_reconcile.util"

local TAG = "__fs_reconcile__"
local INTERVAL_MS = 99
local FLASH_SPAN = 200
local ns = vim.api.nvim_create_namespace "fs-reconcile"

---@class FsReconcileQuiet
---@field LOCAL integer
---@field REMOTE integer

---@type FsReconcileQuiet
local QUIET = {
  LOCAL = 3 * INTERVAL_MS,
  REMOTE = 6 * INTERVAL_MS,
}

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
  return math.max(0, math.ceil(quiet - lib.ns_to_ms(now - at)))
end

---@class FsReconcileResolutions
---@field INITIAL "initial"
---@field SYNCED "synced"
---@field ADOPT "adopt"
---@field SAVE "save"
---@field MERGE "merge"

---@type FsReconcileResolutions
local RESOLUTIONS = {
  INITIAL = "initial",
  SYNCED = "synced",
  ADOPT = "adopt",
  SAVE = "save",
  MERGE = "merge",
}

---@alias FsReconcileResolution "initial"|"synced"|"adopt"|"save"|"merge"

---@class FsReconcileAttestedWrite
---@field type "attested"
---@field base FsReconcileBase
---@field value FsReconcileSnapshot

---@class FsReconcileUnattestedWrite
---@field type "unattested"
---@field value FsReconcileSnapshot

---@alias FsReconcileWrite FsReconcileAttestedWrite|FsReconcileUnattestedWrite

---@class FsReconcileWrites
---@field ATTESTED "attested"
---@field UNATTESTED "unattested"

---@type FsReconcileWrites
local WRITES = {
  ATTESTED = "attested",
  UNATTESTED = "unattested",
}

---@alias FsReconcileChannel AsyncMpsc<FsReconcileEvent>

---@param buf integer
---@return FsReconcileChannel?
local get = function(buf)
  return vim.b[buf][TAG]
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
---@return FsReconcileWrite?
local save = function(buf, path, base, valid)
  vim.api.nvim_exec_autocmds({ "BufWritePre" }, { buffer = buf })
  if not valid() then
    return
  end
  if not util.unchanged(path, base) then
    return
  end
  local ok = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd [[noautocmd silent! write! ++p]]
  end)
  if not ok then
    return
  end
  vim.api.nvim_exec_autocmds({ "BufWritePost" }, { buffer = buf, data = { fs_reconcile = true } })
  local value = util.buffer(buf)
  local after = util.read_file(path, value)
  if after and after.text == value.text then
    return { type = WRITES.ATTESTED, base = after, value = value }
  end
  vim.bo[buf].modified = true
  return { type = WRITES.UNATTESTED, value = value }
end

---@param value FsReconcileSnapshot
---@param base FsReconcileBase
---@param observed FsReconcileBase
---@return string
local merge = function(value, base, observed)
  local text = hunks.merge(value.linefeed, base.text, value.text, observed.text)
  return util.buffer_text(value, text)
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
  hunk_apply.run(buf, value, replacement, mark(buf))
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
---@return fun()
local start = function(buf, path, chan)
  local mpsc_close = chan.close
  ---@type FsReconcilePoller?
  local poller = util.poller(path, INTERVAL_MS, function()
    chan.send(remote())
  end)

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
    if poller then
      poller.close()
      poller = nil
    end
    if vim.api.nvim_buf_is_valid(buf) and attached(buf, chan) then
      vim.b[buf][TAG] = nil
    end
  end

  chan.send(remote())
  return chan.close
end

---@param base? FsReconcileBase
---@param value FsReconcileSnapshot
---@param observed FsReconcileBase
---@return FsReconcileResolution
local resolve = function(base, value, observed)
  if not base then
    return RESOLUTIONS.INITIAL
  elseif value.text == base.text then
    return util.same_base(base, observed) and RESOLUTIONS.SYNCED or RESOLUTIONS.ADOPT
  end
  return util.same_base(base, observed) and RESOLUTIONS.SAVE or RESOLUTIONS.MERGE
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
  local valid = function()
    return attached(buf, chan) and vim.api.nvim_buf_get_name(buf) == path and vim.bo[buf].modifiable
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
      if not valid() then
        goto continue
      end
      local remote_sleep = document.base and document.remote_at and remaining(vim.uv.hrtime(), document.remote_at, QUIET.REMOTE)
        or 0
      if remote_sleep > 0 then
        chan.send(retry(remote_sleep))
        goto continue
      end
      document = next(document, { remote_at = vim.NIL })
      local value = util.buffer(buf)
      if value.changedtick ~= document.changedtick then
        goto continue
      end
      local observed = util.read_file(path, value)
      if not observed then
        goto continue
      end
      local base = document.base
      local resolution = resolve(base, value, observed)
      if resolution == RESOLUTIONS.INITIAL then
        document = next(document, { base = observed })
        if value.text ~= observed.text then
          chan.send(retry(0))
        end
      elseif resolution == RESOLUTIONS.SYNCED then
      elseif resolution == RESOLUTIONS.ADOPT then
        if replace(buf, value, observed.text, valid) then
          vim.bo[buf].modified = false
          document = next(document, { base = observed, local_at = vim.NIL })
        end
      elseif resolution == RESOLUTIONS.SAVE then
        ---@cast base FsReconcileBase
        if document.inserting then
          goto continue
        end
        local local_sleep = document.local_at and remaining(vim.uv.hrtime(), document.local_at, QUIET.LOCAL) or 0
        if local_sleep > 0 then
          chan.send(retry(local_sleep))
          goto continue
        end
        local write = save(buf, path, base, valid)
        if write then
          document = next(document, { changedtick = write.value.changedtick })
          if write.type == WRITES.ATTESTED then
            if valid() then
              document = next(document, { base = write.base, local_at = vim.NIL })
            end
          elseif write.type == WRITES.UNATTESTED then
            if valid() then
              chan.send(remote())
            end
          else
            assert(false, write.type)
          end
        end
      elseif resolution == RESOLUTIONS.MERGE then
        ---@cast base FsReconcileBase
        local text = merge(value, base, observed)
        local changed = text ~= value.text
        if replace(buf, value, text, valid) then
          vim.bo[buf].modified = text ~= observed.text
          document = next(document, { base = observed })
          if vim.bo[buf].modified and not changed then
            chan.send(retry(0))
          end
        end
      else
        assert(false, resolution)
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
  local path, chan, close
  lib.report(function()
    path = vim.api.nvim_buf_get_name(buf)
    if path == "" then
      return
    end
    local existing = get(buf)
    if existing then
      existing.send(remote())
      return
    end
    ---@type FsReconcileChannel
    chan = async.mpsc()
    close = start(buf, path, chan)
    vim.b[buf][TAG] = chan
  end)
  if chan then
    drive(buf, path, chan, close)
  end
end

do
  vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
    group = lib.group,
    command = [[silent! wall! ++p]],
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = async(function(args)
      detach(args.buf)
    end),
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = lib.group,
    callback = async(function(args)
      attach(args.buf)
    end),
  })

  vim.api.nvim_create_autocmd({ "BufFilePost" }, {
    group = lib.group,
    callback = async(function(args)
      detach(args.buf)
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
      local value = util.buffer(args.buf)
      local base = util.read_file(vim.api.nvim_buf_get_name(args.buf), value)
      if base and base.text == value.text then
        send(args.buf, {
          type = EVENTS.WRITE,
          changedtick = value.changedtick,
          base = base,
        })
      else
        send(args.buf, local_change(value.changedtick))
        send(args.buf, remote())
      end
    end),
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = async(function(args)
      vim.v.fcs_choice = ""
      send(args.buf, remote())
    end),
  })

  autocmd.insert_mode(
    { group = lib.group },
    async(function(args)
      send(args.buf, { type = EVENTS.INSERT, inserting = true })
    end),
    async(function(args)
      send(args.buf, { type = EVENTS.INSERT, inserting = false })
    end)
  )

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
    group = lib.group,
    pattern = "modifiable",
    callback = async(function()
      local buf = vim.api.nvim_get_current_buf()
      send(buf, remote())
    end),
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        attach(buf)
      end
    end
  end)
end
