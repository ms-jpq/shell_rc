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
---@field base? FsReconcileBase
---@field inserting boolean
---@field local_at? integer

---@class FsReconcileBindEvent
---@field kind "bind"
---@field path string

---@class FsReconcileInsertEvent
---@field kind "insert"
---@field inserting boolean

---@class FsReconcileLocalEvent
---@field kind "local"
---@field at integer

---@class FsReconcileWakeEvent
---@field kind "wake"

---@alias FsReconcileEvent FsReconcileBindEvent|FsReconcileInsertEvent|FsReconcileLocalEvent|FsReconcileWakeEvent

---@class FsReconcileEventKinds
---@field BIND "bind"
---@field INSERT "insert"
---@field LOCAL "local"
---@field WAKE "wake"

---@type FsReconcileEventKinds
local EVENT = {
  BIND = "bind",
  INSERT = "insert",
  LOCAL = "local",
  WAKE = "wake",
}

---@class FsReconcileAttachment
---@field buf integer
---@field channel AsyncMpsc<FsReconcileEvent>
---@field bind fun()
---@field close fun()

---@class FsReconcileLocal
---@field kind "local"

---@class FsReconcileRemote
---@field kind "remote"
---@field disk FsReconcileBase

---@class FsReconcileConcurrent
---@field kind "concurrent"
---@field disk FsReconcileBase

---@alias FsReconcileChange FsReconcileLocal|FsReconcileRemote|FsReconcileConcurrent

---@class FsReconcileChangeKinds
---@field CONCURRENT "concurrent"
---@field LOCAL "local"
---@field REMOTE "remote"

---@type FsReconcileChangeKinds
local CHANGE = {
  CONCURRENT = "concurrent",
  LOCAL = "local",
  REMOTE = "remote",
}

---@param buf integer
---@return FsReconcileAttachment?
local get = function(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.b[buf][TAG] or nil
end

local mark = function(buf)
  return function(start, finish)
    vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
  end
end

local active = function(buf, path)
  return path ~= "" and vim.bo[buf].modifiable
end

---@param base FsReconcileBase
---@param value FsReconcileSnapshot
---@param disk FsReconcileBase
---@return FsReconcileChange?
local observe = function(base, value, disk)
  if value.text == base.text then
    if not util.same_base(base, disk) then
      return { kind = CHANGE.REMOTE, disk = disk }
    end
  elseif util.same_base(base, disk) then
    return { kind = CHANGE.LOCAL }
  else
    return { kind = CHANGE.CONCURRENT, disk = disk }
  end
end

local save = function(buf, path, base)
  local written = false
  local id = vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    once = true,
    callback = function()
      vim.api.nvim_exec_autocmds("BufWritePre", { buffer = buf })
      if util.unchanged(path, base) then
        vim.cmd [[noautocmd write! ++p]]
        vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf })
        written = true
      end
    end,
  })
  local ok = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd [[silent! write! ++p]]
  end)
  pcall(vim.api.nvim_del_autocmd, id)
  return ok and written
end

local detach = function(buf)
  local attachment = get(buf)
  if attachment then
    vim.b[buf][TAG] = nil
    attachment.close()
  end
end

---@param attachment FsReconcileAttachment
local start = function(attachment)
  local buf = attachment.buf
  if get(buf) ~= attachment then
    return
  end
  ---@type FsReconcileDocument
  local document = {
    path = vim.api.nvim_buf_get_name(buf),
    epoch = 1,
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

  local current = function(epoch)
    if get(buf) == attachment and document.epoch == epoch and active(buf, document.path) then
      return document
    end
  end

  local publish = function(value, base)
    if document.inserting then
      return
    end
    local elapsed = document.local_at and vim.uv.hrtime() - document.local_at or math.huge
    local quiet = lib.ms_to_ns(LOCAL_QUIET_MS)
    local path = document.path
    if elapsed < quiet then
      return
    elseif util.unchanged(path, base) and save(buf, path, base) and current(value.epoch) then
      local after = util.read_file(buf, path, util.buffer(buf, value.epoch))
      if after and current(value.epoch) then
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
    if not active(buf, document.path) then
      return
    end
    local value = util.buffer(buf, document.epoch)
    local observed = util.read_file(buf, document.path, value)
    if not observed or not current(value.epoch) then
      return
    end
    local base = document.base
    if not base then
      next_document { base = observed }
      return
    end
    local guard = function()
      return current(value.epoch) ~= nil
    end
    local change = observe(base, value, observed)
    if not change then
      return
    elseif change.kind == CHANGE.LOCAL then
      publish(value, base)
    elseif change.kind == CHANGE.REMOTE then
      adopt(value, change, guard)
    else
      ---@cast change FsReconcileConcurrent
      merge(value, base, change, guard)
    end
  end

  local drive = function(events)
    for event in events do
      if event.kind == EVENT.BIND then
        if document.path ~= event.path then
          next_document {
            path = event.path,
            epoch = document.epoch + 1,
            base = vim.NIL,
            local_at = vim.bo[buf].modified and vim.uv.hrtime() or vim.NIL,
          }
        end
      elseif event.kind == EVENT.INSERT then
        next_document { inserting = event.inserting }
      elseif event.kind == EVENT.LOCAL then
        next_document { local_at = event.at }
      end
      step()
    end
  end
  drive(attachment.channel.next)
end

local attach = function(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local existing = get(buf)
  if existing then
    existing.bind()
    return
  end
  ---@type AsyncMpsc<FsReconcileEvent>
  local chan = async.mpsc()
  ---@type FsReconcileHandle?
  local poller = nil
  ---@type string?
  local watched_path = nil
  local watching = false
  local closed = false
  local quiet_tick ---@type integer?

  local close = function()
    if closed then
      return
    end
    closed = true
    if poller then
      poller.close()
      poller = nil
    end
    chan.close()
  end
  local quiet = function()
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    if quiet_tick == tick then
      return
    end
    quiet_tick = tick
    vim.defer_fn(function()
      if not closed and quiet_tick == tick and vim.api.nvim_buf_get_changedtick(buf) == tick then
        quiet_tick = nil
        chan.send { kind = EVENT.WAKE }
      end
    end, LOCAL_QUIET_MS)
  end
  local bind = function()
    local path = vim.api.nvim_buf_get_name(buf)
    local enabled = active(buf, path)
    if path ~= watched_path or enabled ~= watching then
      if poller then
        poller.close()
      end
      watched_path = path
      watching = enabled
      poller = enabled and util.poller(path, INTERVAL_MS, function()
        chan.send { kind = EVENT.WAKE }
      end) or nil
    end
    chan.send { kind = EVENT.BIND, path = path }
    if vim.bo[buf].modified then
      quiet()
    end
  end
  ---@type FsReconcileAttachment
  local attachment = { buf = buf, channel = chan, bind = bind, close = close }

  vim.b[buf][TAG] = attachment
  local changed = function()
    if not closed then
      chan.send { kind = EVENT.LOCAL, at = vim.uv.hrtime() }
      quiet()
    end
  end
  vim.api.nvim_buf_attach(buf, false, {
    on_changedtick = changed,
    on_lines = changed,
    on_detach = function(_, detached)
      if get(detached) == attachment then
        vim.b[detached][TAG] = nil
      end
      attachment.close()
    end,
  })
  vim.schedule(async(function()
    start(attachment)
  end))
  attachment.bind()
end

do
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufFilePost", "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      attach(args.buf)
    end,
  })

  autocmd.insert_mode({ group = lib.group }, function(args)
    local attachment = get(args.buf)
    if attachment then
      attachment.channel.send { kind = EVENT.INSERT, inserting = true }
    end
  end, function(args)
    local attachment = get(args.buf)
    if attachment then
      attachment.channel.send { kind = EVENT.INSERT, inserting = false }
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
      attach(vim.api.nvim_get_current_buf())
    end,
  })

  autocmd.vim_enter(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      attach(buf)
    end
  end)
end

return {}
