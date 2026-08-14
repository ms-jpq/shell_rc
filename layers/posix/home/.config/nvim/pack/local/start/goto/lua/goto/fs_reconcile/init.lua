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

---@class FsReconcileDriver
---@field post fun(changes?: table)
---@field bind fun(path: string)
---@field stop fun()

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
---@return FsReconcileDriver?
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

---@param buf integer
---@param path string
---@return FsReconcileDriver
local drive = function(buf, path)
  local document = {
    path = path,
    epoch = 1,
    inserting = vim.api.nvim_get_current_buf() == buf and vim.api.nvim_get_mode().mode:find("^[iR]") ~= nil,
    local_at = vim.bo[buf].modified and vim.uv.hrtime() or nil,
  } ---@type FsReconcileDocument
  local alive = true
  local pending = false
  local resolve ---@type fun()?
  local poller ---@type FsReconcileHandle?
  local watched_path ---@type string?
  local watching = false
  local driver = {} ---@type FsReconcileDriver

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

  local select = function(milliseconds)
    if pending then
      pending = false
      return alive
    end
    local future = async.future()
    local done = false
    local done_once = function()
      if not done then
        done = true
        future.resolve()
      end
    end
    resolve = done_once
    if milliseconds then
      vim.defer_fn(done_once, milliseconds)
    end
    future.await()
    resolve = nil
    pending = false
    return alive
  end

  driver.post = function(changes)
    if changes then
      next_document(changes)
    end
    pending = true
    if resolve then
      vim.schedule(resolve)
    end
  end
  driver.bind = function(next_path)
    if document.path ~= next_path then
      next_document {
        path = next_path,
        epoch = document.epoch + 1,
        base = vim.NIL,
        local_at = vim.bo[buf].modified and vim.uv.hrtime() or vim.NIL,
      }
    end
  end
  driver.stop = function()
    alive = false
    driver.post()
  end

  local current = function(epoch)
    if alive and document.epoch == epoch and active(buf, document.path) then
      return document
    end
  end

  local watch = function()
    local enabled = active(buf, document.path)
    if watched_path == document.path and watching == enabled then
      return
    end
    if poller then
      poller.close()
      poller = nil
    end
    watched_path = document.path
    watching = enabled
    if enabled then
      poller = util.poller(document.path, INTERVAL_MS, driver.post)
    end
  end

  local publish = function(value, base)
    if document.inserting then
      return
    end
    local path = document.path
    local elapsed = document.local_at and vim.uv.hrtime() - document.local_at or math.huge
    local quiet = lib.ms_to_ns(LOCAL_QUIET_MS)
    if elapsed < quiet then
      return math.max(1, math.ceil(lib.ns_to_ms(quiet - elapsed)))
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

  local reconcile = function(value, base, change, guard)
    local merged = hunks.merge(value.linefeed, base.text, value.text, change.disk.text)
    if not guard() then
      return
    end
    local text = util.buffer_text(value, merged)
    if text == value.text or hunks.replace(buf, value, text, mark(buf), nil, guard) then
      vim.bo[buf].modified = text ~= change.disk.text
      next_document { base = change.disk }
      return vim.bo[buf].modified and 0 or nil
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
      return value.text ~= observed.text and 0 or nil
    end
    local guard = function()
      return current(value.epoch) ~= nil
    end
    local change = observe(base, value, observed)
    if not change then
      return
    elseif change.kind == CHANGE.LOCAL then
      return publish(value, base)
    elseif change.kind == CHANGE.REMOTE then
      adopt(value, change, guard)
    else
      ---@cast change FsReconcileConcurrent
      return reconcile(value, base, change, guard)
    end
  end

  async(function()
    local delay
    while select(delay) do
      if get(buf) ~= driver then
        break
      end
      watch()
      delay = step()
    end
    if poller then
      poller.close()
    end
  end)()
  return driver
end

local detach = function(buf)
  local driver = get(buf)
  if driver then
    vim.b[buf][TAG] = nil
    driver.stop()
  end
end

local buffer_attach = function(buf)
  local changed = function()
    local driver = get(buf)
    if driver then
      driver.post { local_at = vim.uv.hrtime() }
    end
  end
  vim.api.nvim_buf_attach(buf, false, {
    on_changedtick = changed,
    on_lines = changed,
    on_detach = function(_, detached)
      detach(detached)
    end,
  })
end

local attach = function(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local path = vim.api.nvim_buf_get_name(buf)
  local driver = get(buf)
  if driver then
    driver.bind(path)
  else
    driver = drive(buf, path)
    vim.b[buf][TAG] = driver
    buffer_attach(buf)
  end
  driver.post()
end

do
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufFilePost", "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      attach(args.buf)
    end,
  })

  autocmd.insert_mode(
    { group = lib.group },
    function(args)
      local driver = get(args.buf)
      if driver then
        driver.post { inserting = true }
      end
    end,
    function(args)
      local driver = get(args.buf)
      if driver then
        driver.post { inserting = false }
      end
    end
  )

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
