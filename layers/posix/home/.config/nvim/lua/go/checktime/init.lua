local async = require "go.async"
local lib = require "go.lib"
local reload = require "go.checktime.reload"
local snapshot = require "go.checktime.snapshot"
local watch = require "go.checktime.watch"

-- no backup
vim.opt.backup = false
vim.opt.writebackup = false

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowriteall = true
vim.opt.autoread = false

vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
  group = lib.group,
  command = [[silent! wall! ++p]],
})

do
  local alive = lib.generation "checktime"
  local check_interval = 99
  local watcher = watch.start()

  local reconcile = function()
    for buf in pairs(watcher.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        local remote = name ~= "" and snapshot.read(name)
        if remote then
          reload.reconcile(buf, remote)
        end
      end
    end
    vim.cmd [[silent! wall! ++p]]
  end

  async.run(function()
    while alive() do
      async.sleep(check_interval)
      if alive() then
        reconcile()
      end
    end
  end)
end
