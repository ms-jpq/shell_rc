local async = require "goto.async"
local execute = require "goto.checktime.stages.3-execute"
local ingress = require "goto.checktime.stages.1-ingress"
local lib = require "goto.lib"
local lock = require "goto.checktime.lock"
local resolve = require "goto.checktime.stages.2-resolve"

vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.confirm = true
vim.opt.autowriteall = true
vim.opt.autoread = false

do
  local alive = lib.generation "checktime"
  local visible_interval, hidden_interval = 99, 999
  local local_debounce_ms = 3 * visible_interval
  local remote_quiet_ms = 6 * visible_interval
  local inbox = ingress.start {
    local_debounce_ms = local_debounce_ms,
    remote_quiet_ms = remote_quiet_ms,
    visible_interval = visible_interval,
    hidden_interval = hidden_interval,
  }
  local executor = execute.start(inbox.commit)
  local resolver = resolve.start { local_grace_ms = local_debounce_ms }

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
      async.sleep(visible_interval)
      lib.report(tick)
    end
  end)
end
