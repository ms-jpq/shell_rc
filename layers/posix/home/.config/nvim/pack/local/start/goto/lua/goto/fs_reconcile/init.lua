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

---@class FsReconcileBase
---@field text string
---@field version? uv.fs_stat.result

---@class FsReconcileSnapshot: FsReconcileBuffer
---@field changedtick integer
---@field epoch integer

---@class FsReconcileDocument
---@field path string
---@field epoch integer
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
---@field epoch integer
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

local detach = function(buf)
  local chan = get(buf)
  if chan then
    chan.close()
  end
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
---@param chan FsReconcileChannel
---@param close fun()
local drive = function(buf, chan, close)
  ---@type FsReconcileDocument
  local document = {
    path = vim.api.nvim_buf_get_name(buf),
    epoch = 1,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    inserting = vim.api.nvim_get_current_buf() == buf and vim.api.nvim_get_mode().mode:find "^[iR]" ~= nil,
    local_at = vim.bo[buf].modified and vim.uv.hrtime() or nil,
  }
  local valid = function(epoch)
    return document.epoch == epoch
      and document.path ~= ""
      and vim.api.nvim_buf_get_name(buf) == document.path
      and vim.bo[buf].modifiable
  end

  return lib.scope(function(defer)
    defer(close)
    for event in chan do
      if event.type == EVENTS.RETRY then
        if event.epoch ~= document.epoch then
          goto continue
        end
        local elapsed = chan.wait(event.sleep)
        if not elapsed or event.epoch ~= document.epoch then
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
      local path = vim.api.nvim_buf_get_name(buf)
      if document.path ~= path then
        document = next(document, {
          path = path,
          epoch = document.epoch + 1,
          changedtick = vim.api.nvim_buf_get_changedtick(buf),
          base = vim.NIL,
          local_at = vim.bo[buf].modified and vim.uv.hrtime() or vim.NIL,
        })
      end
      if not valid(document.epoch) then
        goto continue
      end
      local value = util.buffer(buf, document.epoch)
      if value.changedtick ~= document.changedtick then
        goto continue
      end
      local observed = util.read_file(buf, document.path, value)
      if not observed or not valid(value.epoch) then
        goto continue
      end
      local base = document.base
      if not base then
        document = next(document, { base = observed })
        if value.text ~= observed.text then
          chan.send {
            type = EVENTS.RETRY,
            epoch = document.epoch,
            sleep = 0,
          }
        end
        goto continue
      end
      local guard = function()
        return valid(value.epoch)
      end
      if value.text == base.text then
        if util.same_base(base, observed) then
          goto continue
        end
        if value.text == observed.text or hunks.replace(buf, value, observed.text, mark(buf), nil, guard) then
          vim.bo[buf].modified = false
          document = next(document, { base = observed, local_at = vim.NIL })
        end
        goto continue
      end
      if util.same_base(base, observed) then
        if document.inserting then
          goto continue
        end
        local elapsed = document.local_at and lib.ns_to_ms(vim.uv.hrtime() - document.local_at) or math.huge
        if elapsed < LOCAL_QUIET_MS then
          local sleep = math.ceil(LOCAL_QUIET_MS - elapsed)
          chan.send {
            type = EVENTS.RETRY,
            epoch = document.epoch,
            sleep = sleep,
          }
          goto continue
        end
        vim.api.nvim_exec_autocmds({ "BufWritePre" }, { buffer = buf })
        if not util.unchanged(document.path, base) then
          goto continue
        end
        local ok = pcall(vim.api.nvim_buf_call, buf, function()
          vim.cmd [[noautocmd write! ++p]]
        end)
        if not ok then
          goto continue
        end
        vim.api.nvim_exec_autocmds({ "BufWritePost" }, { buffer = buf })
        if not valid(value.epoch) then
          goto continue
        end
        local after = util.read_file(buf, document.path, util.buffer(buf, value.epoch))
        if after and valid(value.epoch) then
          document = next(document, { base = after, local_at = vim.NIL })
        end
        goto continue
      end
      local merged = hunks.merge(value.linefeed, base.text, value.text, observed.text)
      if not guard() then
        goto continue
      end
      local text = util.buffer_text(value, merged)
      local changed = text ~= value.text
      if not changed or hunks.replace(buf, value, text, mark(buf), nil, guard) then
        vim.bo[buf].modified = text ~= observed.text
        document = next(document, { base = observed })
        if vim.bo[buf].modified and not changed then
          chan.send {
            type = EVENTS.RETRY,
            epoch = document.epoch,
            sleep = 0,
          }
        end
      end
      ::continue::
    end
  end)
end

---@param buf integer
---@param chan FsReconcileChannel
---@return fun()
local start = function(buf, chan)
  ---@type FsReconcilePoller?
  local poller = nil
  local watch = function()
    local path = vim.api.nvim_buf_get_name(buf)
    if poller and poller.path ~= path then
      poller.close()
      poller = nil
    end
    if path ~= "" and not poller then
      poller = util.poller(path, INTERVAL_MS, function()
        chan.send { type = EVENTS.REMOTE }
      end)
    end
    chan.send { type = EVENTS.REMOTE }
  end
  local file_post = vim.api.nvim_create_autocmd({ "BufFilePost" }, {
    group = lib.group,
    buffer = buf,
    callback = async(function()
      watch()
    end),
  })

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
  watch()

  local close = function()
    chan.close()
    vim.api.nvim_del_autocmd(file_post)
    if poller then
      poller.close()
      poller = nil
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf][TAG] = nil
    end
  end

  return close
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
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = lib.group,
    callback = async(function(args)
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

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = async(function(args)
      detach(args.buf)
    end),
  })

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

return {}
