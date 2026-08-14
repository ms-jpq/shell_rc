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

---@class FsReconcileLocal
---@field kind "local"

---@class FsReconcileRemote
---@field kind "remote"
---@field disk FsReconcileBase

---@class FsReconcileConcurrent
---@field kind "concurrent"
---@field disk FsReconcileBase

---@alias FsReconcileChange FsReconcileLocal|FsReconcileRemote|FsReconcileConcurrent

---@class FsReconcileChanges
---@field CONCURRENT "concurrent"
---@field LOCAL "local"
---@field REMOTE "remote"

---@type FsReconcileChanges
local CHANGES = {
  CONCURRENT = "concurrent",
  LOCAL = "local",
  REMOTE = "remote",
}

---@param buf integer
---@return FsReconcileChannel?
local get = function(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.b[buf][TAG] or nil
end

local mark = function(buf)
  return function(start, finish)
    vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
  end
end

local active = function(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.api.nvim_buf_is_loaded(buf)
    and vim.api.nvim_buf_get_name(buf) ~= ""
    and vim.bo[buf].modifiable
end

---@param base FsReconcileBase
---@param value FsReconcileSnapshot
---@param disk FsReconcileBase
---@return FsReconcileChange?
local observe = function(base, value, disk)
  if value.text == base.text then
    if not util.same_base(base, disk) then
      return { kind = CHANGES.REMOTE, disk = disk }
    end
  elseif util.same_base(base, disk) then
    return { kind = CHANGES.LOCAL }
  else
    return { kind = CHANGES.CONCURRENT, disk = disk }
  end
end

local save = function(buf, path, base)
  vim.api.nvim_exec_autocmds("BufWritePre", { buffer = buf })
  if not util.unchanged(path, base) then
    return false
  end
  local ok = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd [[noautocmd write! ++p]]
  end)
  if ok then
    vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf })
  end
  return ok
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
  return lib.scope(function(defer)
    defer(close)
    ---@type FsReconcileDocument
    local document = {
      path = vim.api.nvim_buf_get_name(buf),
      epoch = 1,
      changedtick = vim.api.nvim_buf_get_changedtick(buf),
      inserting = vim.api.nvim_get_current_buf() == buf and vim.api.nvim_get_mode().mode:find "^[iR]" ~= nil,
      local_at = vim.bo[buf].modified and vim.uv.hrtime() or nil,
    }
    local next_document = function(changes)
      local next = vim.tbl_extend("force", {}, document)
      ---@cast next FsReconcileDocument
      for key, value in pairs(changes or {}) do
        if value == vim.NIL then
          next[key] = nil
        else
          next[key] = value
        end
      end
      document = next
      return document
    end

    local valid = function(epoch)
      return document.epoch == epoch and active(buf) and vim.api.nvim_buf_get_name(buf) == document.path
    end

    local retry = function(sleep)
      chan.send { type = EVENTS.RETRY, sleep = sleep }
    end

    local publish = function(value, base)
      if document.inserting then
        return
      end
      local elapsed = document.local_at and vim.uv.hrtime() - document.local_at or math.huge
      local quiet = lib.ms_to_ns(LOCAL_QUIET_MS)
      local path = document.path
      if elapsed < quiet then
        retry(quiet - elapsed)
      elseif util.unchanged(path, base) and save(buf, path, base) and valid(value.epoch) then
        local after = util.read_file(buf, path, util.buffer(buf, value.epoch))
        if after and valid(value.epoch) then
          next_document { base = after, local_at = vim.NIL }
        end
      end
    end

    local adopt = function(value, change, guard)
      if value.text == change.disk.text or hunks.replace(buf, value, change.disk.text, mark(buf), nil, guard) then
        vim.bo[buf].modified = false
        next_document { base = change.disk, local_at = vim.NIL }
      end
    end

    local merge = function(value, base, change, guard)
      local merged = hunks.merge(value.linefeed, base.text, value.text, change.disk.text)
      if not guard() then
        return
      end
      local text = util.buffer_text(value, merged)
      local changed = text ~= value.text
      if not changed or hunks.replace(buf, value, text, mark(buf), nil, guard) then
        vim.bo[buf].modified = text ~= change.disk.text
        next_document { base = change.disk }
        if vim.bo[buf].modified and not changed then
          publish(value, change.disk)
        end
      end
    end

    local step = function()
      if not valid(document.epoch) then
        return
      end
      local value = util.buffer(buf, document.epoch)
      if value.changedtick ~= document.changedtick then
        return
      end
      local observed = util.read_file(buf, document.path, value)
      if not observed or not valid(value.epoch) then
        return
      end
      local base = document.base
      if not base then
        next_document { base = observed }
        if value.text ~= observed.text then
          retry(0)
        end
        return
      end
      local guard = function()
        return valid(value.epoch)
      end
      local change = observe(base, value, observed)
      if not change then
        return
      elseif change.kind == CHANGES.LOCAL then
        publish(value, base)
      elseif change.kind == CHANGES.REMOTE then
        adopt(value, change, guard)
      else
        ---@cast change FsReconcileConcurrent
        merge(value, base, change, guard)
      end
    end

    for event in chan.next do
      if event.type ~= EVENTS.RETRY or chan.wait(event.sleep) then
        local path = vim.api.nvim_buf_get_name(buf)
        if document.path ~= path then
          next_document {
            path = path,
            epoch = document.epoch + 1,
            changedtick = vim.api.nvim_buf_get_changedtick(buf),
            base = vim.NIL,
            local_at = vim.bo[buf].modified and vim.uv.hrtime() or vim.NIL,
          }
        end
        if event.type == EVENTS.INSERT then
          next_document { inserting = event.inserting }
        elseif event.type == EVENTS.LOCAL then
          next_document { local_at = event.at, changedtick = event.changedtick }
        end
        step()
      end
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
  local file_post = vim.api.nvim_create_autocmd("BufFilePost", {
    group = lib.group,
    buffer = buf,
    callback = watch,
  })
  local closed = false
  local mpsc_close = chan.close
  local close = function()
    if closed then
      return
    end
    closed = true
    mpsc_close()
    vim.api.nvim_del_autocmd(file_post)
    if poller then
      poller.close()
      poller = nil
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf][TAG] = nil
      vim.api.nvim_buf_detach(buf)
    end
  end

  local changed = function()
    if not closed then
      chan.send {
        type = EVENTS.LOCAL,
        at = vim.uv.hrtime(),
        changedtick = vim.api.nvim_buf_get_changedtick(buf),
      }
    end
  end
  vim.api.nvim_buf_attach(buf, false, {
    on_changedtick = changed,
    on_lines = changed,
    on_detach = function()
      chan.close()
    end,
  })
  watch()
  return close
end

local attach = function(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local existing = get(buf)
  if existing then
    existing.send { type = EVENTS.REMOTE }
    return
  end
  ---@type FsReconcileChannel
  local chan = async.mpsc()
  vim.b[buf][TAG] = chan
  local close = start(buf, chan)
  vim.schedule(async(function()
    drive(buf, chan, close)
  end))
end

do
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = lib.group,
    callback = function(args)
      attach(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = lib.group,
    callback = function(args)
      local chan = get(args.buf)
      if chan then
        chan.send { type = EVENTS.REMOTE }
      end
    end,
  })

  autocmd.insert_mode({ group = lib.group }, function(args)
    local chan = get(args.buf)
    if chan then
      chan.send { type = EVENTS.INSERT, inserting = true }
    end
  end, function(args)
    local chan = get(args.buf)
    if chan then
      chan.send { type = EVENTS.INSERT, inserting = false }
    end
  end)

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      detach(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("OptionSet", {
    group = lib.group,
    pattern = "modifiable",
    callback = function()
      local chan = get(vim.api.nvim_get_current_buf())
      if chan then
        chan.send { type = EVENTS.REMOTE }
      end
    end,
  })

  autocmd.vim_enter(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      attach(buf)
    end
  end)
end

return {}
