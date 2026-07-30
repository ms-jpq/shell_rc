local async = require "go.async"
local hunks = require "go.checktime.hunks"
local lib = require "go.lib"
local lock = require "go.checktime.lock"
local poll = require "go.checktime.poll"
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
  local check_interval, flash_span = 99, 1688
  local ns = vim.api.nvim_create_namespace "go.checktime"
  local watcher = watch.start()

  vim.api.nvim_create_autocmd({ "FocusGained" }, {
    group = lib.group,
    callback = function()
      watcher.dirty(poll.REMOTE)
    end,
  })

  local flash = function(buf, text)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    hunks.replace(buf, text, function(start, finish)
      vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = flash_span })
    end)
  end

  local reconcile = function(buf, remote)
    local current = snapshot.current(buf)
    local base = vim.b[buf][snapshot.BASE] or current.text

    local win = vim.api.nvim_get_current_win()
    local pos = vim.api.nvim_win_get_buf(win) == buf and vim.api.nvim_win_get_cursor(win) or {}
    local text = hunks.merge(
      current.linefeed,
      snapshot.row_text(current, base),
      current.text,
      snapshot.row_text(current, remote),
      pos
    )
    local eol_fixed = snapshot.buffer_text(current, text)

    if eol_fixed ~= current.text then
      flash(buf, eol_fixed)
    end

    vim.b[buf][snapshot.BASE] = remote
    vim.bo[buf].modified = eol_fixed ~= remote
  end

  local tick = function()
    for buf, changes in pairs(watcher.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modifiable then
        local name = vim.api.nvim_buf_get_name(buf)
        local locked = lock.guard(name, function()
          if changes[poll.REMOTE] then
            local remote = snapshot.read(buf)
            if remote == snapshot.RETRY then
              watcher.dirty(poll.REMOTE, buf)
              return
            elseif remote then
              reconcile(buf, remote)
            end
          end

          if vim.bo[buf].modified then
            vim.api.nvim_buf_call(buf, function()
              vim.cmd [[silent! write! ++p]]
            end)
          end
        end)
        if not locked then
          if changes[poll.LOCAL] then
            watcher.dirty(poll.LOCAL, buf)
          end
          if changes[poll.REMOTE] then
            watcher.dirty(poll.REMOTE, buf)
          end
        end
      end
    end
  end

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = function()
      vim.v.fcs_choice = ""
    end,
  })

  async.run(function()
    while true do
      async.sleep(check_interval)
      if not alive() then
        return
      end
      lib.report(tick)
    end
  end)
end
