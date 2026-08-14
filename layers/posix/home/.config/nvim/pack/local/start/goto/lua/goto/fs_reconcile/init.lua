local async = require "goto.async"
local autocmd = require "goto.autocmd"
local hunks = require "goto.fs_reconcile.hunks"
local lib = require "goto.lib"
local util = require "goto.fs_reconcile.util"

local M = {}

---@type fun(buf: integer)
local wake

local TAG = "__fs_reconcile__"
local INTERVAL_MS = 99
local LOCAL_QUIET_MS = 3 * INTERVAL_MS
local MAX_BYTES = 2 * 1024 * 1024
local FLASH_SPAN = 200
local ns = vim.api.nvim_create_namespace "fs-reconcile"

---@class FsReconcileBase
---@field text string
---@field version? uv.fs_stat.result

---@class FsReconcileSnapshot: FsReconcileBuffer
---@field changedtick integer

---@class FsReconcileHandle
---@field close fun()

---@class FsReconcileState
---@field path string
---@field base? FsReconcileBase
---@field enabled boolean
---@field inserting boolean
---@field local_at? integer
---@field pending boolean
---@field running boolean
---@field poller? FsReconcileHandle

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

M.state = {
  ---@param buf integer
  ---@return FsReconcileState?
  get = function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.b[buf][TAG] or nil
  end,

  ---@param buf integer
  ---@param state FsReconcileState
  put = function(buf, state)
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf][TAG] = state
    end
  end,
}

local mark = function(buf)
  return function(start, finish)
    vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
  end
end

---@param buf integer
---@param path string
---@param value FsReconcileSnapshot
---@return FsReconcileBase?
local read_file = function(buf, path, value)
  local before = vim.uv.fs_stat(path)
  if not before then
    return { text = "" }
  elseif before.size > MAX_BYTES then
    return
  end
  local ok, text = pcall(vim.fn.readblob, path)
  if not ok or type(text) ~= "string" then
    return
  end
  text = util.decode(buf, text)
  local after = vim.uv.fs_stat(path)
  if not text or not util.same_version(before, after) then
    return
  end
  return { text = util.buffer_text(value, util.merge_text(value, text)), version = before }
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
  local state = M.state.get(buf)
  if state then
    if state.poller then
      state.poller.close()
    end
    vim.b[buf][TAG] = nil
  end
end

local wrap = function(handle, stop)
  local closed = false
  return {
    close = function()
      if closed then
        return
      end
      closed = true
      if stop then
        handle:stop()
      end
      handle:close()
    end,
  }
end

local poller = function(buf, path)
  local poll = vim.uv.new_fs_poll()
  if not poll then
    return
  elseif poll:start(
    path,
    INTERVAL_MS,
    vim.schedule_wrap(function()
      wake(buf)
    end)
  ) then
    return wrap(poll, true)
  end
  poll:close()
end

local retry = async(function(buf, milliseconds)
  async.sleep(milliseconds)
  wake(buf)
end)

local defer = function(buf)
  local state = M.state.get(buf)
  if not state or not state.enabled then
    return
  end
  M.state.put(
    buf,
    lib.copy(state, {
      local_at = vim.uv.hrtime(),
      pending = state.running or state.pending,
    })
  )
  retry(buf, LOCAL_QUIET_MS)
end

local commit = function(buf, path, next)
  local state = M.state.get(buf)
  if not state or not state.enabled or state.path ~= path then
    return false
  elseif state.pending then
    next = lib.copy(next, {
      inserting = state.inserting,
      local_at = state.local_at,
      pending = true,
      poller = state.poller,
    })
  end
  M.state.put(buf, next)
  return true
end

local publish = function(buf, path, state, base, next)
  if state.inserting then
    commit(buf, path, next)
    return
  end
  local elapsed = next.local_at and vim.uv.hrtime() - next.local_at or math.huge
  local quiet = LOCAL_QUIET_MS * lib.NANOSECONDS_PER_MILLISECOND
  if elapsed < quiet then
    retry(buf, math.max(1, math.ceil((quiet - elapsed) / lib.NANOSECONDS_PER_MILLISECOND)))
  elseif util.unchanged(path, base) and save(buf, path, base) then
    local after = read_file(buf, path, util.buffer(buf))
    if after then
      next = lib.copy(next, { base = after, local_at = nil })
    end
  end
  commit(buf, path, next)
end

local adopt = function(buf, path, value, change, next)
  if value.text == change.disk.text or hunks.replace(buf, value, change.disk.text, mark(buf)) then
    next = lib.copy(next, { base = change.disk, local_at = nil })
    vim.bo[buf].modified = false
  end
  commit(buf, path, next)
end

local reconcile = function(buf, path, value, base, change, next)
  local merged = hunks.merge(value.linefeed, base.text, value.text, change.disk.text)
  local text = util.buffer_text(value, merged)
  if text == value.text or hunks.replace(buf, value, text, mark(buf)) then
    vim.bo[buf].modified = text ~= change.disk.text
    next = lib.copy(next, { base = change.disk })
  end
  if commit(buf, path, next) and vim.bo[buf].modified then
    defer(buf)
  end
end

local drive = function(buf, path)
  local state = M.state.get(buf)
  if not state or not state.enabled or state.path ~= path then
    return
  end
  local value = util.buffer(buf)
  local observed = read_file(buf, path, value)
  state = M.state.get(buf)
  if not state or not state.enabled or state.path ~= path then
    return
  elseif not observed then
    commit(buf, path, lib.copy(state, { running = false }))
    return
  end
  local next = lib.copy(state, { running = false })
  local base = state.base
  if not base then
    next = lib.copy(next, { base = observed })
    if commit(buf, path, next) then
      wake(buf)
    end
    return
  end
  ---@cast base FsReconcileBase
  local change = observe(base, value, observed)
  if not change then
    commit(buf, path, next)
  elseif change.kind == CHANGE.LOCAL then
    publish(buf, path, state, base, next)
  elseif change.kind == CHANGE.REMOTE then
    adopt(buf, path, value, change, next)
  else
    ---@cast change FsReconcileConcurrent
    reconcile(buf, path, value, base, change, next)
  end
end

wake = function(buf)
  local state = M.state.get(buf)
  if not state or not state.enabled then
    return
  elseif state.running then
    M.state.put(buf, lib.copy(state, { pending = true }))
    return
  end
  local next = lib.copy(state, { running = true, pending = false })
  M.state.put(buf, next)
  async.run(function()
    lib.report(drive, buf, next.path)
    local after = M.state.get(buf)
    if after and after.pending then
      M.state.put(buf, lib.copy(after, { pending = false }))
      wake(buf)
    end
  end)
end

local bind = function(buf, path, enabled)
  local old = M.state.get(buf)
  if old and old.path == path and old.enabled == enabled then
    return old
  end
  if old then
    if old.poller then
      old.poller.close()
    end
  end
  local state = old
      and old.path == path
      and lib.copy(old, {
        enabled = enabled,
        inserting = old.inserting,
        pending = false,
        poller = nil,
        running = false,
      })
    or {
      path = path,
      base = nil,
      enabled = enabled,
      inserting = false,
      local_at = vim.bo[buf].modified and vim.uv.hrtime() or nil,
      pending = false,
      running = false,
    }
  if not enabled then
    M.state.put(buf, state)
    return state
  end
  state = lib.copy(state, { poller = poller(buf, path) })
  M.state.put(buf, state)
  if not old then
    local schedule_defer = function()
      vim.schedule(function()
        defer(buf)
      end)
    end
    vim.api.nvim_buf_attach(buf, false, {
      on_changedtick = schedule_defer,
      on_lines = schedule_defer,
      on_detach = function()
        detach(buf)
      end,
    })
  end
  if vim.bo[buf].modified then
    defer(buf)
  end
  return state
end

local attach = function(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local path = vim.api.nvim_buf_get_name(buf)
  local state = bind(buf, path, vim.bo[buf].modifiable and path ~= "")
  if state.enabled then
    wake(buf)
  end
end

do
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufFilePost", "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      attach(args.buf)
    end,
  })

  local set_inserting = function(args, inserting)
    local state = M.state.get(args.buf)
    if state then
      M.state.put(args.buf, lib.copy(state, { inserting = inserting }))
    end
    wake(args.buf)
  end
  autocmd.insert_mode({ group = lib.group }, function(args)
    set_inserting(args, true)
  end, function(args)
    set_inserting(args, false)
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

return M
