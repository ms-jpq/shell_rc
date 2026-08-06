local async = require "goto.async"
local execute = require "goto.checktime.stages.3-execute"
local lib = require "goto.lib"
local lock = require "goto.checktime.lock"
local mailbox = require "goto.checktime.stages.1-mailbox"
local resolve = require "goto.checktime.stages.2-resolve"

vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.confirm = true
vim.opt.autowriteall = true
vim.opt.autoread = false

do
  local alive = lib.generation "checktime"
  local interval = 99
  local inbox = mailbox.start()
  local executor = execute.start(inbox.commit)
  local resolver = resolve.start { grace_ms = 3 * interval }

  local tick = function()
    for buf, changedtick in pairs(inbox.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        lock.guard(vim.api.nvim_buf_get_name(buf), function()
          if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_buf_is_loaded(buf)
            or not vim.bo[buf].modifiable
          then
            return
          end

          local batch = inbox.latest(buf, changedtick)
          if not batch then
            return
          end
          local instruction = resolver.plan(buf, batch)
          executor.run(buf, batch, instruction)
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
