local async = require "go.async"
local lib = require "go.lib"
local reload = require "go.checktime.reload"
local snapshot = require "go.checktime.snapshot"

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowriteall = true
vim.opt.autoread = false

-- no backup
vim.opt.backup = false
vim.opt.writebackup = false

local remember = function(buf)
  snapshot.set(buf, vim.api.nvim_buf_get_lines(buf, 0, -1, true))
end

for _, buf in pairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) then
    remember(buf)
  end
end

do
  local alive = lib.generation "checktime"
  local check_interval = 99
  local blocked, queued = {}, {}

  local drain = function()
    local changes = queued
    queued = {}

    for buf, remote in pairs(changes) do
      if vim.api.nvim_buf_is_valid(buf) then
        reload.reconcile(buf, remote)
      end
    end
  end

  local sync = function()
    vim.cmd.checktime { mods = { silent = true, emsg_silent = true } }
    drain()
    if not next(blocked) then
      vim.cmd [[silent! wall! ++p]]
    end
  end

  vim.api.nvim_create_autocmd({ "VimLeavePre", "FocusLost" }, {
    group = lib.group,
    callback = sync,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      blocked[args.buf] = nil
      queued[args.buf] = nil
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      queued[args.buf] = nil
      blocked[args.buf] = nil
      remember(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name == "" then
        return
      end
      queued[args.buf] = nil
      if not vim.uv.fs_stat(name) then
        blocked[args.buf] = true
        error("checktime: " .. name, 0)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    group = lib.group,
    callback = function(args)
      remember(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      local remote = name ~= "" and snapshot.read(name)
      vim.v.fcs_choice = remote and "" or "ask"
      if remote then
        blocked[args.buf] = nil
        queued[args.buf] = remote
      else
        blocked[args.buf] = true
      end
    end,
  })

  async.run(function()
    while alive() do
      async.sleep(check_interval)
      if alive() then
        sync()
      end
    end
  end)
end
