local async = require "goto.async"
local autocmd = require "goto.autocmd"
local hunk_apply = require "goto.fs_reconcile.hunks.apply"
local hunks = require "goto.fs_reconcile.hunks"
local lib = require "goto.lib"
local util = require "goto.fs_reconcile.util"

vim.opt.autoread = false
vim.opt.backup = false
vim.opt.writebackup = false

local TAG = "__fs_reconcile__"
local INTERVAL_MS = 99
local FLASH_SPAN = 200

local ns = vim.api.nvim_create_namespace "fs-reconcile"
local group = vim.api.nvim_create_augroup("lv_fs_reconcile", { clear = true })

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
  return math.max(0, math.floor(quiet - lib.ns_to_ms(now - at)))
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

---@param document FsReconcileDocument
---@param event FsReconcileEvent
---@return FsReconcileDocument
---@return integer?
local transition = function(document, event)
  if event.type == EVENTS.RETRY then
    return document, event.sleep > 0 and event.sleep or nil
  elseif event.type == EVENTS.INSERT then
    return next(document, { inserting = event.inserting })
  elseif event.type == EVENTS.LOCAL then
    if event.changedtick == document.changedtick then
      return document
    end
    return next(document, { local_at = event.at, changedtick = event.changedtick })
  elseif event.type == EVENTS.WRITE then
    return next(document, {
      base = event.base,
      changedtick = event.changedtick,
      local_at = vim.NIL,
    })
  elseif event.type == EVENTS.REMOTE then
    return next(document, { remote_at = event.at })
  end
  assert(false, event.type)
  return document
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
  local active = function()
    return attached(buf, chan) and vim.api.nvim_buf_get_name(buf) == path
  end
  local valid = function()
    return active() and vim.bo[buf].modifiable
  end

  lib.scope(function(defer)
    defer(close)
    for event in chan do
      local sleep
      document, sleep = transition(document, event)
      if sleep then
        local elapsed = chan.wait(sleep)
        if not elapsed then
          goto continue
        end
      end
      if not active() then
        goto continue
      elseif not vim.bo[buf].modifiable then
        chan.send(retry(QUIET.REMOTE))
        goto continue
      end
      local value = util.buffer(buf)
      if value.changedtick ~= document.changedtick then
        document = next(document, {
          changedtick = value.changedtick,
          local_at = vim.bo[buf].modified and vim.uv.hrtime() or vim.NIL,
        })
        chan.send(remote())
        goto continue
      end
      local observed, state = util.read_file(path, value)
      if not observed then
        if state == util.READ.UNSTABLE then
          chan.send(retry(QUIET.REMOTE))
        end
        goto continue
      end
      local base = document.base
      if base and not util.same_base(base, observed) and util.same_file(base.version, observed.version) then
        local remote_at = document.remote_at or vim.uv.hrtime()
        local remote_sleep = remaining(vim.uv.hrtime(), remote_at, QUIET.REMOTE)
        if remote_sleep > 0 then
          document = next(document, { remote_at = remote_at })
          chan.send(retry(remote_sleep))
          goto continue
        end
      end
      document = next(document, { remote_at = vim.NIL })
      local resolution = resolve(base, value, observed)
      if resolution == RESOLUTIONS.INITIAL then
        if vim.bo[buf].modified and observed.version and value.text ~= observed.text then
          local text = merge(value, { text = "" }, observed)
          if replace(buf, value, text, valid) then
            vim.bo[buf].modified = text ~= observed.text
            document = next(document, { base = observed, changedtick = vim.api.nvim_buf_get_changedtick(buf) })
          end
        else
          document = next(document, { base = observed })
        end
        if not document.base or value.text ~= observed.text then
          chan.send(retry(0))
        end
      elseif resolution == RESOLUTIONS.SYNCED then
      elseif resolution == RESOLUTIONS.ADOPT then
        if replace(buf, value, observed.text, valid) then
          vim.bo[buf].modified = false
          document = next(document, {
            base = observed,
            changedtick = vim.api.nvim_buf_get_changedtick(buf),
            local_at = vim.NIL,
          })
        end
      elseif resolution == RESOLUTIONS.SAVE then
        ---@cast base FsReconcileBase
        if document.inserting or vim.bo[buf].readonly then
          goto continue
        end
        local local_sleep = document.local_at and remaining(vim.uv.hrtime(), document.local_at, QUIET.LOCAL) or 0
        if local_sleep > 0 then
          chan.send(retry(local_sleep))
          goto continue
        end
        local write = save(buf, path, base, valid)
        if not write then
          goto continue
        end
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
      elseif resolution == RESOLUTIONS.MERGE then
        ---@cast base FsReconcileBase
        if observed.version or not base.version then
          local text = merge(value, base, observed)
          if replace(buf, value, text, valid) then
            vim.bo[buf].modified = text ~= observed.text
            document = next(document, { base = observed, changedtick = vim.api.nvim_buf_get_changedtick(buf) })
            if vim.bo[buf].modified then
              chan.send(retry(0))
            end
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
    vim.bo[buf].autoread = false
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

---@param buf integer
local native_write = function(buf)
  local value = util.buffer(buf)
  local base = util.read_file(vim.api.nvim_buf_get_name(buf), value)
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

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = group,
    callback = async(function(args)
      detach(args.buf)
    end),
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
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
    pattern = { "autoread", "modifiable", "readonly" },
    callback = function(args)
      local buf = vim.api.nvim_get_current_buf()
      if args.match == "autoread" then
        vim.bo[buf].autoread = false
      end
      send(buf, remote())
    end,
  })

  autocmd.vim_enter(function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        attach(buf)
      end
    end
  end, { group = group })
end
