local async = require "goto.async"
local hunks = require "goto.checktime.hunks"
local lib = require "goto.lib"
local lock = require "goto.checktime.lock"
local poll = require "goto.checktime.poll"
local snapshot = require "goto.checktime.snapshot"
local watch = require "goto.checktime.watch"

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
  local ns = vim.api.nvim_create_namespace "goto.checktime"
  local watcher = watch.start()

  vim.api.nvim_create_autocmd({ "FocusGained" }, {
    group = lib.group,
    callback = function()
      watcher.dirty(poll.REMOTE)
    end,
  })

  ---@param buf integer
  ---@param text string
  local flash = function(buf, text)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    hunks.replace(buf, text, function(start, finish)
      vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = flash_span })
    end)
  end

  ---@param buf integer
  ---@param base string?
  ---@param remote string
  ---@return string
  local reconcile = function(buf, base, remote)
    local current = snapshot.current(buf)

    local text = hunks.merge(
      current.linefeed,
      snapshot.row_text(current, base or ""),
      current.text,
      snapshot.row_text(current, remote)
    )
    local eol_fixed = snapshot.buffer_text(current, text)

    if eol_fixed ~= current.text then
      flash(buf, eol_fixed)
    end

    watcher.remember(buf, remote)
    vim.bo[buf].modified = eol_fixed ~= remote
    return remote
  end

  ---@param buf integer
  ---@param base string?
  local write = function(buf, base)
    if not snapshot.matches(buf, base) then
      watcher.dirty(poll.REMOTE, buf)
      return
    end

    vim.api.nvim_buf_call(buf, function()
      vim.cmd [[silent! write! ++p]]
    end)
  end

  local tick = function()
    for buf, update in pairs(watcher.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modifiable then
        local name = vim.api.nvim_buf_get_name(buf)
        local locked = lock.guard(name, function()
          local base = update.base
          if update.dirty[poll.REMOTE] then
            local state, remote = snapshot.read(buf)
            if state == snapshot.STATES.RETRY then
              watcher.dirty(poll.REMOTE, buf)
              return
            elseif state == snapshot.STATES.OPAQUE then
              vim.api.nvim_buf_call(buf, function()
                vim.cmd [[silent! edit]]
              end)
            elseif state == snapshot.STATES.RECONCILE and remote then
              base = reconcile(buf, base, remote)
            end
          end

          if vim.bo[buf].modified then
            write(buf, base)
          end
        end)
        if not locked then
          if update.dirty[poll.LOCAL] then
            watcher.dirty(poll.LOCAL, buf)
          end
          if update.dirty[poll.REMOTE] then
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
