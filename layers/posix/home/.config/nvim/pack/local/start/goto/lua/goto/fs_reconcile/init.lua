local async = require "goto.async"
local autocmd = require "goto.autocmd"
local hunks = require "goto.fs_reconcile.hunks"
local lib = require "goto.lib"
local util = require "goto.fs_reconcile.util"

local TAG = "__fs_reconcile__"
local INTERVAL_MS = 99
local LOCAL_QUIET_MS = 3 * INTERVAL_MS
local FLASH_SPAN = 200
local ns = vim.api.nvim_create_namespace "fs-reconcile"

---@class FsReconcileDocument
---@field changedtick integer
---@field base? FsReconcileBase
---@field inserting boolean
---@field local_at? integer

---@class FsReconcileInsertEvent
---@field type "insert"
---@field inserting boolean

---@class FsReconcileLocalEvent
---@field type "local"
---@field at integer
---@field changedtick integer

---@class FsReconcileRemoteEvent
---@field type "remote"

---@class FsReconcileRetryEvent
---@field type "retry"
---@field sleep integer

---@alias FsReconcileEvent FsReconcileInsertEvent|FsReconcileLocalEvent|FsReconcileRemoteEvent|FsReconcileRetryEvent

---@class FsReconcileEvents
---@field INSERT "insert"
---@field LOCAL "local"
---@field RETRY "retry"
---@field REMOTE "remote"

---@type FsReconcileEvents
local EVENTS = {
  INSERT = "insert",
  LOCAL = "local",
  RETRY = "retry",
  REMOTE = "remote",
}

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

---@alias FsReconcileChannel AsyncMpsc<FsReconcileEvent>

---@param buf integer
---@return FsReconcileChannel?
local get = function(buf)
  return vim.b[buf][TAG]
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
---@return FsReconcileBase?
local save = function(buf, path, base)
  vim.api.nvim_exec_autocmds({ "BufWritePre" }, { buffer = buf })
  if not util.unchanged(path, base) then
    return
  end
  local ok = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd [[noautocmd write! ++p]]
  end)
  if not ok then
    return
  end
  vim.api.nvim_exec_autocmds({ "BufWritePost" }, { buffer = buf })
  return util.read_file(path, util.buffer(buf))
end

---@param value FsReconcileSnapshot
---@param base FsReconcileBase
---@param observed FsReconcileBase
---@return string
local merge = function(value, base, observed)
  local text = hunks.merge(value.linefeed, base.text, value.text, observed.text)
  return util.buffer_text(value, text)
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
---@param chan FsReconcileChannel
---@return fun()
local start = function(buf, chan)
  local path = vim.api.nvim_buf_get_name(buf)
  ---@type FsReconcilePoller?
  local poller = path ~= "" and util.poller(path, INTERVAL_MS, function()
    chan.send { type = EVENTS.REMOTE }
  end) or nil

  local changed = async(function(_, _, changedtick)
    chan.send {
      type = EVENTS.LOCAL,
      at = vim.uv.hrtime(),
      changedtick = changedtick,
    }
  end)
  vim.api.nvim_buf_attach(buf, false, {
    on_changedtick = changed,
    on_lines = changed,
    on_detach = function()
      chan.close()
    end,
  })
  chan.send { type = EVENTS.REMOTE }

  local close = function()
    chan.close()
    if poller then
      poller.close()
      poller = nil
    end
    if vim.api.nvim_buf_is_valid(buf) and get(buf) == chan then
      vim.b[buf][TAG] = nil
    end
  end

  return close
end

local detach = function(buf)
  local chan = get(buf)
  if chan then
    chan.close()
  end
end

---@param buf integer
---@param chan FsReconcileChannel
---@param close fun()
local drive = function(buf, chan, close)
  local path = vim.api.nvim_buf_get_name(buf)
  ---@type FsReconcileDocument
  local document = {
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    inserting = vim.api.nvim_get_current_buf() == buf and vim.api.nvim_get_mode().mode:find "^[iR]" ~= nil,
    local_at = vim.bo[buf].modified and vim.uv.hrtime() or nil,
  }
  local valid = function()
    return get(buf) == chan and path ~= "" and vim.api.nvim_buf_get_name(buf) == path and vim.bo[buf].modifiable
  end
  local replace = function(value, text)
    if value.text == text then
      return true
    end
    local replacement = hunks.replacement(value, text)
    if not valid() then
      return false
    end
    local applied = hunks.apply(buf, value, replacement, mark(buf))
    return applied
  end

  return lib.scope(function(defer)
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
      elseif event.type == EVENTS.REMOTE then
      else
        assert(false, event.type)
      end
      if not valid() then
        goto continue
      end
      local value = util.buffer(buf)
      if value.changedtick ~= document.changedtick then
        goto continue
      end
      local observed = util.read_file(path, value)
      if not observed or not valid() then
        goto continue
      end
      local base = document.base
      local resolution = resolve(base, value, observed)
      if resolution == RESOLUTIONS.INITIAL then
        document = next(document, { base = observed })
        if value.text ~= observed.text then
          chan.send {
            type = EVENTS.RETRY,
            sleep = 0,
          }
        end
      elseif resolution == RESOLUTIONS.SYNCED then
      elseif resolution == RESOLUTIONS.ADOPT then
        if replace(value, observed.text) then
          vim.bo[buf].modified = false
          document = next(document, { base = observed, local_at = vim.NIL })
        end
      elseif resolution == RESOLUTIONS.SAVE then
        ---@cast base FsReconcileBase
        if document.inserting then
          goto continue
        end
        local elapsed = document.local_at and lib.ns_to_ms(vim.uv.hrtime() - document.local_at) or math.huge
        if elapsed < LOCAL_QUIET_MS then
          local sleep = math.ceil(LOCAL_QUIET_MS - elapsed)
          chan.send {
            type = EVENTS.RETRY,
            sleep = sleep,
          }
          goto continue
        end
        local after = save(buf, path, base)
        if after and valid() then
          document = next(document, { base = after, local_at = vim.NIL })
        end
      elseif resolution == RESOLUTIONS.MERGE then
        ---@cast base FsReconcileBase
        local text = merge(value, base, observed)
        local changed = text ~= value.text
        if replace(value, text) then
          vim.bo[buf].modified = text ~= observed.text
          document = next(document, { base = observed })
          if vim.bo[buf].modified and not changed then
            chan.send {
              type = EVENTS.RETRY,
              sleep = 0,
            }
          end
        end
      else
        assert(false, resolution)
      end
      ::continue::
    end
  end)
end

local attach = function(buf)
  local existing = get(buf)
  if existing then
    existing.send { type = EVENTS.REMOTE }
    return
  end
  ---@type FsReconcileChannel
  local chan = async.mpsc()
  vim.b[buf][TAG] = chan
  local close = start(buf, chan)
  drive(buf, chan, close)
end

do
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
      send(args.buf, { type = EVENTS.REMOTE })
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
      send(buf, { type = EVENTS.REMOTE })
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
