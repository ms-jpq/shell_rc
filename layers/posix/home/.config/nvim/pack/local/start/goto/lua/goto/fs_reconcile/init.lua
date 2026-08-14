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
---@field epoch integer

---@class FsReconcileHandle
---@field close fun()

---@class FsReconcileState
---@field path string
---@field epoch integer
---@field base? FsReconcileBase
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
  ---@param init fun(): FsReconcileState
  ---@return FsReconcileState
  get_or_init = function(buf, init)
    return M.state.get(buf) or M.state.next(buf, init())
  end,

  ---@param buf integer
  ---@param state FsReconcileState
  ---@param changes? table
  ---@return FsReconcileState
  next = function(buf, state, changes)
    local current = M.state.get(buf)
    local next = vim.tbl_extend("force", {}, state, changes or {})
    ---@cast next FsReconcileState
    if current then
      local before = current.poller and current.poller.close
      local after = next.poller and next.poller.close
      next.epoch = current.epoch + ((next.path ~= current.path or after ~= before) and 1 or 0)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf][TAG] = next
    end
    return next
  end,
}

local mark = function(buf)
  return function(start, finish)
    vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = FLASH_SPAN })
  end
end

local active = function(buf, path)
  return path ~= "" and vim.bo[buf].modifiable
end

---@param buf integer
---@param path string
---@param epoch integer
---@return FsReconcileState?
local current = function(buf, path, epoch)
  local state = M.state.get(buf)
  if state and state.path == path and state.epoch == epoch and active(buf, path) then
    return state
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

local poller = function(buf, path)
  local poll = vim.uv.new_fs_poll()
  local changed = async(function()
    async.scheduled()
    wake(buf)
  end)
  if not poll then
    return
  elseif poll:start(path, INTERVAL_MS, changed) then
    local closed = false
    return {
      close = function()
        if not closed then
          closed = true
          poll:stop()
          poll:close()
        end
      end,
    }
  end
  poll:close()
end

local retry = async(function(buf, milliseconds)
  async.sleep(milliseconds)
  wake(buf)
end)

local defer = function(buf)
  local state = M.state.get(buf)
  if not state or not active(buf, state.path) then
    return
  end
  M.state.next(buf, state, {
    local_at = vim.uv.hrtime(),
    pending = state.running or state.pending,
  })
  retry(buf, LOCAL_QUIET_MS)
end

local commit = function(buf, path, epoch, changes)
  local state = current(buf, path, epoch)
  if not state then
    return false
  elseif state.pending then
    changes = vim.tbl_extend("force", {}, changes, {
      inserting = state.inserting,
      local_at = state.local_at,
      pending = true,
      poller = state.poller,
    })
  end
  M.state.next(buf, state, changes)
  return true
end

local publish = function(buf, path, epoch, state, base, changes)
  if state.inserting then
    commit(buf, path, epoch, changes)
    return
  end
  local elapsed = state.local_at and vim.uv.hrtime() - state.local_at or math.huge
  local quiet = LOCAL_QUIET_MS * lib.NANOSECONDS_PER_MILLISECOND
  if elapsed < quiet then
    retry(buf, math.max(1, math.ceil((quiet - elapsed) / lib.NANOSECONDS_PER_MILLISECOND)))
  elseif util.unchanged(path, base) and save(buf, path, base) then
    local after = read_file(buf, path, util.buffer(buf, epoch))
    if after then
      changes.base = after
      changes.local_at = nil
    end
  end
  commit(buf, path, epoch, changes)
end

local adopt = function(buf, path, epoch, value, change, changes, guard)
  if value.text == change.disk.text or hunks.replace(buf, value, change.disk.text, mark(buf), nil, guard) then
    changes.base = change.disk
    changes.local_at = nil
    vim.bo[buf].modified = false
  end
  commit(buf, path, epoch, changes)
end

local reconcile = function(buf, path, epoch, value, base, change, changes, guard)
  local merged = hunks.merge(value.linefeed, base.text, value.text, change.disk.text)
  if not guard() then
    return
  end
  local text = util.buffer_text(value, merged)
  if text == value.text or hunks.replace(buf, value, text, mark(buf), nil, guard) then
    vim.bo[buf].modified = text ~= change.disk.text
    changes.base = change.disk
  end
  if commit(buf, path, epoch, changes) and vim.bo[buf].modified then
    defer(buf)
  end
end

local drive = function(buf, path, epoch)
  local state = current(buf, path, epoch)
  if not state then
    return
  end
  local value = util.buffer(buf, state.epoch)
  local observed = read_file(buf, path, value)
  state = current(buf, path, value.epoch)
  if not state then
    return
  elseif not observed then
    return
  end
  local base = state.base
  if not base then
    if commit(buf, path, epoch, { base = observed }) then
      wake(buf)
    end
    return
  end
  ---@cast base FsReconcileBase
  local guard = function()
    return current(buf, path, value.epoch) ~= nil
  end
  local change = observe(base, value, observed)
  if not change then
    commit(buf, path, epoch, {})
  elseif change.kind == CHANGE.LOCAL then
    publish(buf, path, epoch, state, base, {})
  elseif change.kind == CHANGE.REMOTE then
    adopt(buf, path, epoch, value, change, {}, guard)
  else
    ---@cast change FsReconcileConcurrent
    reconcile(buf, path, epoch, value, base, change, {}, guard)
  end
end

---@param buf integer
---@param path string
---@param epoch integer
local drain = function(buf, path, epoch)
  while true do
    local state = M.state.get(buf)
    if not state or state.path ~= path or state.epoch ~= epoch then
      return
    elseif not state.pending then
      M.state.next(buf, state, { running = false })
      return
    end
    M.state.next(buf, state, { pending = false })
    drive(buf, path, epoch)
  end
end

wake = function(buf)
  local state = M.state.get(buf)
  if not state or not active(buf, state.path) then
    return
  elseif state.running then
    M.state.next(buf, state, { pending = true })
    return
  end
  local next = M.state.next(buf, state, { running = true, pending = true })
  drain(buf, next.path, next.epoch)
end

local buffer_attach = function(buf)
  local changed = async(function()
    async.scheduled()
    defer(buf)
  end)
  vim.api.nvim_buf_attach(buf, false, {
    on_changedtick = changed,
    on_lines = changed,
    on_detach = function(_, detached)
      detach(detached)
    end,
  })
end

local bind = function(buf, path)
  local old = M.state.get(buf)
  local enabled = active(buf, path)
  if old and old.path == path and enabled == (old.poller ~= nil) then
    return old
  end
  if old then
    if old.poller then
      old.poller.close()
    end
  end
  local state = old and M.state.next(buf, old, {
    path = path,
    base = old.path == path and old.base or nil,
    inserting = old.inserting,
    local_at = old.path == path and old.local_at or vim.bo[buf].modified and vim.uv.hrtime() or nil,
    pending = false,
    poller = enabled and poller(buf, path) or nil,
    running = false,
  }) or M.state.get_or_init(buf, function()
    return {
      path = path,
      epoch = 1,
      base = nil,
      inserting = false,
      local_at = vim.bo[buf].modified and vim.uv.hrtime() or nil,
      pending = false,
      poller = enabled and poller(buf, path) or nil,
      running = false,
    }
  end)
  if not enabled then
    return state
  end
  if not old then
    buffer_attach(buf)
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
  bind(buf, path)
  if active(buf, path) then
    wake(buf)
  end
end

do
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufFilePost", "BufWritePost" }, {
    group = lib.group,
    callback = async(function(args)
      attach(args.buf)
    end),
  })

  local set_inserting = function(args, inserting)
    local state = M.state.get(args.buf)
    if state then
      M.state.next(args.buf, state, { inserting = inserting })
    end
    wake(args.buf)
  end
  autocmd.insert_mode(
    { group = lib.group },
    async(function(args)
      set_inserting(args, true)
    end),
    async(function(args)
      set_inserting(args, false)
    end)
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
    callback = async(function()
      attach(vim.api.nvim_get_current_buf())
    end),
  })

  autocmd.vim_enter(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      attach(buf)
    end
  end)
end

return M
