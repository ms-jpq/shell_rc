local async = require "goto.async"
local execute = require "goto.checktime.stages.4-execute"
local lib = require "goto.lib"
local lock = require "goto.checktime.lock"
local mailbox = require "goto.checktime.stages.1-mailbox"
local plan = require "goto.checktime.stages.3-plan"
local resolve = require "goto.checktime.stages.2-resolve"
local snapshot = require "goto.checktime.snapshot"

vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.confirm = true
vim.opt.autowriteall = true
vim.opt.autoread = false

do
  local alive = lib.generation "checktime"
  local interval = 99
  local inbox = mailbox.start()
  local dispatch = inbox.dispatch
  local EVENTS = mailbox.EVENTS
  snapshot.start(function(buf)
    dispatch { kind = EVENTS.DIRTY, change = "remote", buf = buf, watch = false }
  end)
  local executor = execute.start { dispatch = dispatch }

  local tick = function()
    for buf, batch in pairs(inbox.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        lock.guard(vim.api.nvim_buf_get_name(buf), function()
          if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_buf_is_loaded(buf)
            or not vim.bo[buf].modifiable
          then
            return
          end

          dispatch { kind = EVENTS.SAMPLE, buf = buf, changedtick = batch.changedtick }
          local latest = inbox.latest(buf, batch)
          local resolution = resolve.gather(buf, latest)
          executor.run(buf, latest, plan.compute(resolution))
        end)
      end
    end
  end

  async.run(function()
    while alive() do
      async.sleep(interval)
      lib.report(tick)
    end
  end)
end
