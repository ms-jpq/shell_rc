local async = require "go.async"
local lib = require "go.lib"
local reload = require "go.checktime.reload"
local snapshot = require "go.checktime.snapshot"
local watch = require "go.checktime.watch"

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowriteall = true
vim.opt.autoread = false

-- no backup
vim.opt.backup = false
vim.opt.writebackup = false

vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
  group = lib.group,
  command = [[silent! wall! ++p]],
})

do
  local alive = lib.generation "checktime"
  local check_interval = 99
  local watcher = watch.start()

  local blocked = {}
  local clear = function(buf)
    blocked[buf] = nil
  end

  local remember = function(buf)
    snapshot.set(buf, vim.api.nvim_buf_get_lines(buf, 0, -1, true))
  end

  local reconcile = function()
    for buf in pairs(watcher.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        local remote = name ~= "" and snapshot.read(name)
        if remote then
          clear(buf)
          reload.reconcile(buf, remote)
        else
          blocked[buf] = true
        end
      end
    end
  end

  local write = function()
    vim.cmd [[wall! ++p]]
  end

  local sync = function()
    reconcile()
    if not next(blocked) then
      write()
    end
  end

  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      remember(buf)
    end
  end

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = lib.group,
    callback = function(args)
      clear(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      clear(args.buf)
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

  async.run(function()
    while alive() do
      async.sleep(check_interval)
      if alive() then
        sync()
      end
    end
  end)
end
