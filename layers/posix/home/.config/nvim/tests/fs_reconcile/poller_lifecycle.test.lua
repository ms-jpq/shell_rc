local T = require "tests.lib"

T.test({ "polling reports its first error and recovers after creation" }, function()
  local util = require "goto.fs_reconcile.util"
  local path = vim.fs.joinpath(T.tempdir(), "missing")
  local observations = 0
  local poller = assert(util.poller(path, 10, function()
    observations = observations + 1
  end))
  T.cleanup(poller.close)
  T.eventually(function()
    return observations == 1
  end)
  require("goto.async").sleep(40)
  T.eq(1, observations)
  vim.fn.writefile({ "created" }, path)
  T.eventually(function()
    return observations == 2
  end)
  assert(vim.uv.fs_unlink(path))
  T.eventually(function()
    return observations == 3
  end)
  poller.close()
  poller.close()
  vim.fn.writefile({ "after close" }, path)
  require("goto.async").sleep(40)
  T.eq(3, observations)
end)

T.test({ "closing a poller suppresses its pending initial observation" }, function()
  local util = require "goto.fs_reconcile.util"
  local path = T.file { "base" }
  local workers = {}
  local completed = 0
  for _ = 1, 8 do
    local worker = vim.uv.new_work(function()
      vim.uv.sleep(50)
    end, function()
      completed = completed + 1
    end)
    table.insert(workers, worker)
    worker:queue()
  end
  local requested = false
  local stat = vim.uv.fs_stat
  T.patch(vim.uv, "fs_stat", function(name, callback)
    requested = true
    return stat(name, callback)
  end)
  local observations = 0
  local poller = assert(util.poller(path, 10, function()
    observations = observations + 1
  end))
  T.cleanup(poller.close)
  T.eventually(function()
    return requested
  end, { interval = 1 })
  poller.close()
  T.eventually(function()
    return completed == #workers
  end)
  require("goto.async").scheduled()
  T.eq(0, observations)
end)
