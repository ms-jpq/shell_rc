local async = require "go.async"
local hunks = require "go.checktime.hunks"
local lib = require "go.lib"
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
  local check_interval, flash_span = 99, 888
  local ns = vim.api.nvim_create_namespace "go.checktime"
  local watcher = watch.start()

  vim.api.nvim_create_autocmd({ "FocusGained" }, {
    group = lib.group,
    callback = watcher.dirty_all,
  })

  local flash = function(buf, lines)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    hunks.replace(buf, lines, function(start, finish)
      vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = flash_span })
    end)
  end

  local reconcile = function(buf, remote)
    local local_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    local base = vim.b[buf][snapshot.BASE] or local_lines

    local win = vim.api.nvim_get_current_win()
    local pos = vim.api.nvim_win_get_buf(win) == buf and vim.api.nvim_win_get_cursor(win) or {}
    local lines = hunks.merge(base, local_lines, remote, pos)

    if not vim.deep_equal(lines, local_lines) then
      flash(buf, lines)
    end

    vim.b[buf][snapshot.BASE] = remote
    vim.bo[buf].modified = not vim.deep_equal(lines, remote)
  end

  local tick = function()
    if not alive() then
      return
    end
    for buf in pairs(watcher.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modifiable then
        local name = vim.api.nvim_buf_get_name(buf)
        local remote = name ~= "" and snapshot.read(buf)
        if remote then
          reconcile(buf, remote)
        end
      end
    end
    vim.cmd [[silent! wall! ++p]]
  end

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = function()
      vim.v.fcs_choice = ""
    end,
  })

  async.run(function()
    while alive() do
      async.sleep(check_interval)
      lib.report(tick)
    end
  end)
end
