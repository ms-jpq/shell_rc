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

local check_visible = function()
  local checked = {}

  for _, win in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not checked[buf] then
      checked[buf] = true
      vim.cmd.checktime { tostring(buf), mods = { silent = true, emsg_silent = true } }
    end
  end
end

do
  local alive = lib.generation "checktime"
  local check_interval = 99
  local queued = {}
  local scheduled = false

  local drain = function()
    scheduled = false
    local changes = queued
    queued = {}

    for buf, remote in pairs(changes) do
      if vim.api.nvim_buf_is_valid(buf) then
        reload.reconcile(buf, remote)
      end
    end
  end

  local enqueue = function(buf, remote)
    queued[buf] = remote
    if not scheduled then
      scheduled = true
      vim.schedule(drain)
    end
  end

  local sync_visible = function()
    check_visible()
    if not next(queued) then
      vim.cmd [[silent! wall! ++p]]
    end
  end

  vim.api.nvim_create_autocmd({ "VimLeavePre", "FocusLost" }, {
    group = lib.group,
    command = [[silent! wall! ++p]],
  })

  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name == "" then
        return
      end
      queued[args.buf] = nil
      if not reload.from_file(args.buf, name) then
        error("checktime: " .. name, 0)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    group = lib.group,
    callback = function(args)
      local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, true)
      snapshot.set(args.buf, lines)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name ~= "" then
        queued[args.buf] = nil
        reload.from_file(args.buf, name)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      local remote = name ~= "" and snapshot.read(name)
      vim.v.fcs_choice = remote and "" or "ask"
      if remote then
        enqueue(args.buf, remote)
      end
    end,
  })

  async.run(function()
    while alive() do
      async.sleep(check_interval)
      if alive() then
        sync_visible()
      end
    end
  end)
end
