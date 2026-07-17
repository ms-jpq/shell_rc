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

  local reload_changes = nil
  reload_changes = lib.throttle(check_interval, function()
    if not alive() then
      return
    end

    local changes = queued
    queued = {}

    for buf, name in pairs(changes) do
      if vim.api.nvim_buf_is_valid(buf) then
        local _, retry = reload.apply(buf, name)
        if retry then
          queued[buf] = name
        end
      end
    end

    if not vim.tbl_isempty(queued) then
      reload_changes()
    end
  end)

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
      reload.buf_write_pre(args.buf, name)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    group = lib.group,
    callback = function(args)
      snapshot.set(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name ~= "" then
        reload.apply(args.buf, name)
      else
        snapshot.set(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = function(args)
      vim.v.fcs_choice = ""
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name == "" then
        return
      end
      queued[args.buf] = name
      reload_changes()
    end,
  })

  async.run(function()
    while alive() do
      async.sleep(check_interval)
      if alive() then
        check_visible()
      end
    end
  end)
end
