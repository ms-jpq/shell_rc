local async = require "goto.async"
local controller = require "goto.checktime.controller"
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
  ---@param current ChecktimeCurrent
  ---@param text string
  local flash = function(buf, current, text)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    hunks.replace(buf, current, text, function(start, finish)
      vim.hl.range(buf, ns, "HighlightedyankRegion", { start, 0 }, { finish - 1, -1 }, { timeout = flash_span })
    end)
  end

  ---@param buf integer
  ---@param base string?
  ---@param remote string
  ---@param version uv.fs_stat.result?
  ---@return string, uv.fs_stat.result?
  local reconcile = function(buf, base, remote, version)
    local current = snapshot.current(buf)

    local text = hunks.merge(
      current.linefeed,
      snapshot.row_text(current, base or ""),
      snapshot.row_text(current, current.text),
      snapshot.row_text(current, remote)
    )
    local eol_fixed = snapshot.buffer_text(current, text)

    if eol_fixed ~= current.text then
      flash(buf, current, eol_fixed)
    end

    watcher.remember(buf, remote, version)
    vim.bo[buf].modified = eol_fixed ~= snapshot.fit(current, remote)
    return remote, version
  end

  ---@param buf integer
  ---@return boolean
  local write = function(buf)
    local ok = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd [[write! ++p]]
    end)
    return ok and not vim.bo[buf].modified
  end

  local sync = controller.new {
    read = function(buf)
      return snapshot.read(buf)
    end,
    reconcile = reconcile,
    reload = function(buf)
      return pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd [[edit]]
      end)
    end,
    modified = function(buf)
      return vim.bo[buf].modified
    end,
    unchanged = function(buf, version)
      return snapshot.unchanged(buf, version)
    end,
    write = write,
  }

  ---@param buf integer
  ---@param update ChecktimeUpdate
  local requeue = function(buf, update)
    for kind in pairs(update.dirty) do
      watcher.dirty(kind, buf)
    end
  end

  local tick = function()
    for buf, update in pairs(watcher.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        if not vim.bo[buf].modifiable then
          requeue(buf, update)
          goto continue
        end
        local name = vim.api.nvim_buf_get_name(buf)
        local completed = false
        local locked = lock.guard(name, function()
          if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
            return
          end
          if vim.bo[buf].modifiable then
            completed = sync.step(buf, update)
          end
        end)
        if (not locked or not completed) and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
          requeue(buf, update)
        end
      end
      ::continue::
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
