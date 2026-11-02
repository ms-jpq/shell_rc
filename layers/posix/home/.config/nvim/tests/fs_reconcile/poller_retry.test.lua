local T = require "tests.lib"

T.test({ "poller retry", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)

  local util = require "goto.fs_reconcile.util"
  local poller = util.poller
  local attempts = 0
  T.patch(util, "poller", function(...)
    attempts = attempts + 1
    if attempts == 1 then
      return
    end
    return poller(...)
  end)

  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})

  assert(attempts == 1, vim.inspect { attempts = attempts })
  assert(vim.bo.autoread)

  vim.api.nvim_exec_autocmds({ "BufEnter" }, { buffer = 0 })
  assert(attempts == 2, vim.inspect { attempts = attempts })
  assert(not vim.bo.autoread)

  vim.fn.writefile({ "agent" }, path)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        attempts = attempts,
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        modified = vim.bo.modified,
      }
    end,
  })
end)
