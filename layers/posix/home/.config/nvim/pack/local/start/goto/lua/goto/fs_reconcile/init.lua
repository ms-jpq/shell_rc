local async = require "goto.async"
local autocmd = require "goto.autocmd"
local hunks = require "goto.fs_reconcile.hunks"
local lib = require "goto.lib"
local util = require "goto.fs_reconcile.util"

local M = {}

---@type fun(buf: integer, changes?: table)
local wake
---@type fun(buf: integer)
local drive

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
  ---@param state FsReconcileState
  ---@param changes? table
  ---@return FsReconcileState?
  next = function(buf, state, changes)
    local current = M.state.get(buf)
    if current and (current.path ~= state.path or current.epoch ~= state.epoch) then
      return
    end
    local next = vim.tbl_extend("force", {}, state)
    ---@cast next FsReconcileState
    for key, value in pairs(changes or {}) do
      if value == vim.NIL then
        next[key] = nil
      else
        next[key] = value
      end
    end
    local changed_source = false
    if current then
      local before = current.poller and current.poller.close
      local after = next.poller and next.poller.close
      changed_source = next.path ~= current.path or after ~= before
    end
    if current and current.pending and not changed_source and (not changes or changes.pending == nil) then
      vim.tbl_extend("force", next, {
        inserting = current.inserting,
        local_at = current.local_at,
        pending = true,
      })
    end
    if current then
      next.epoch = current.epoch + (changed_source and 1 or 0)
    end
    vim.b[buf][TAG] = next
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
  local id = vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buffer = buf,
    once = true,
    callback = function()
      vim.api.nvim_exec_autocmds({ "BufWritePre" }, { buffer = buf })
      if util.unchanged(path, base) then
        vim.cmd [[noautocmd write! ++p]]
        vim.api.nvim_exec_autocmds({ "BufWritePost" }, { buffer = buf })
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

local detach = function(buf)
  local state = M.state.get(buf)
  if state then
    if state.poller then
      state.poller.close()
    end
    vim.b[buf][TAG] = nil
  end
end

local publish = function(buf, path, state, base)
  if state.inserting then
    M.state.next(buf, state)
    return
  end
  local elapsed = state.local_at and vim.uv.hrtime() - state.local_at or math.huge
  local quiet = lib.ms_to_ns(LOCAL_QUIET_MS)
  if elapsed < quiet then
    retry(buf, math.max(1, math.ceil(lib.ns_to_ms(quiet - elapsed))))
  elseif util.unchanged(path, base) and save(buf, path, base) then
    local after = util.read_file(buf, path, util.buffer(buf, state.epoch))
    if after then
      M.state.next(buf, state, { base = after, local_at = vim.NIL })
      return
    end
  end
  M.state.next(buf, state)
end

local adopt = function(buf, state, value, change, guard)
  if value.text == change.disk.text or hunks.replace(buf, value, change.disk.text, mark(buf), nil, guard) then
    vim.bo[buf].modified = false
    M.state.next(buf, state, { base = change.disk, local_at = vim.NIL })
    return
  end
  M.state.next(buf, state)
end

local reconcile = function(buf, state, value, base, change, guard)
  local merged = hunks.merge(value.linefeed, base.text, value.text, change.disk.text)
  if not guard() then
    return
  end
  local text = util.buffer_text(value, merged)
  if text == value.text or hunks.replace(buf, value, text, mark(buf), nil, guard) then
    vim.bo[buf].modified = text ~= change.disk.text
    if M.state.next(buf, state, { base = change.disk }) and vim.bo[buf].modified then
      defer(buf)
    end
  else
    M.state.next(buf, state)
  end
end

local step = function(buf, path, epoch)
  local state = current(buf, path, epoch)
  if not state then
    return
  end
  local value = util.buffer(buf, state.epoch)
  local observed = util.read_file(buf, path, value)
  state = current(buf, path, value.epoch)
  if not state then
    return
  elseif not observed then
    return
  end
  local base = state.base
  if not base then
    M.state.next(buf, state, { base = observed })
    return
  end
  ---@cast base FsReconcileBase
  local guard = function()
    return current(buf, path, value.epoch) ~= nil
  end
  local change = observe(base, value, observed)
  if not change then
    M.state.next(buf, state)
  elseif change.kind == CHANGE.LOCAL then
    publish(buf, path, state, base)
  elseif change.kind == CHANGE.REMOTE then
    adopt(buf, state, value, change, guard)
  else
    ---@cast change FsReconcileConcurrent
    reconcile(buf, state, value, base, change, guard)
  end
end

---@param buf integer
drive = function(buf)
  while true do
    local state = M.state.get(buf)
    if not state or not active(buf, state.path) then
      return
    elseif not state.pending then
      M.state.next(buf, state, { running = false })
      return
    end
    local next = M.state.next(buf, state, { pending = false })
    if not next then
      return
    end
    step(buf, next.path, next.epoch)
  end
end

wake = function(buf, changes)
  local state = M.state.get(buf)
  if not state or not active(buf, state.path) then
    return
  elseif state.running then
    M.state.next(buf, state, { pending = true })
    return
  end
  local next = M.state.next(buf, state, vim.tbl_extend("force", changes or {}, {
    running = true,
    pending = true,
  }))
  if next then
    drive(buf)
  end
end

local buffer_attach = function(buf)
  local queued = false
  local changed = async(function()
    if queued then
      return
    end
    queued = true
    async.scheduled()
    queued = false
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
  if old and old.poller then
    old.poller.close()
  end
  local state
  if old then
    state = M.state.next(buf, old, {
      path = path,
      base = old.path == path and old.base or vim.NIL,
      inserting = old.inserting,
      local_at = old.path == path and old.local_at or vim.bo[buf].modified and vim.uv.hrtime() or vim.NIL,
      pending = false,
      poller = enabled and util.poller(path, INTERVAL_MS, function()
        wake(buf)
      end) or vim.NIL,
      running = false,
    })
  else
    state = assert(M.state.next(buf, {
      path = path,
      epoch = 1,
      base = nil,
      inserting = false,
      local_at = vim.bo[buf].modified and vim.uv.hrtime() or nil,
      pending = false,
      poller = enabled and util.poller(path, INTERVAL_MS, function()
        wake(buf)
      end) or nil,
      running = false,
    }))
  end
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
    wake(args.buf, { inserting = inserting })
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

  vim.api.nvim_create_autocmd({ "OptionSet" }, {
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
