local T = require "tests.lib"

T.test({ "polling observes creation during the initial read gap", timeout = 10000 }, function()
  local workers = {}
  for _ = 1, 8 do
    local worker = vim.uv.new_work(function()
      vim.uv.sleep(150)
    end, function() end)
    table.insert(workers, worker)
    worker:queue()
  end

  local path = vim.fn.tempname()
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  assert(vim.b.__fs_reconcile__ ~= nil)

  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.modified
  end, {
    timeout = 1500,
    message = function()
      return vim.inspect { buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true), disk = vim.fn.readfile(path) }
    end,
  })
end)
