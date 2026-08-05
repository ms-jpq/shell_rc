local async = require "goto.async"
local execute = require "goto.checktime.stages.4-execute"
local lib = require "goto.lib"
local lock = require "goto.checktime.lock"
local mailbox = require "goto.checktime.stages.1-mailbox"
local plan = require "goto.checktime.stages.3-plan"
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
  local executor = execute.start(inbox.remember)

  local tick = function()
    for buf, batch in pairs(inbox.take()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        local complete = lock.guard(vim.api.nvim_buf_get_name(buf), function()
          if not (vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modifiable) then
            return false
          end
          local facts = resolve.gather(buf, batch, inbox.latest(buf, batch.events))
          return executor.run(buf, plan.compute(facts))
        end)
        if not complete and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
          inbox.restore(buf, batch)
        end
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
