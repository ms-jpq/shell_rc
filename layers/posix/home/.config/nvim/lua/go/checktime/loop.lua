local async = require "go.async"

local M = {}

M.new = function(timeout)
  local queued, waiting = {}, nil

  local state = {}

  local wake = function(waiting_for)
    if waiting_for and waiting == waiting_for then
      waiting = nil
      vim.schedule(waiting_for.resolve)
    end
  end

  local wait = function()
    local f = async.future()
    waiting = f
    vim.defer_fn(function()
      wake(f)
    end, timeout)
    f.await()
  end

  local drain = function()
    local q = queued
    queued = {}

    return q
  end

  state.queue_change = function(buf, name)
    queued[buf] = { name = name }
    wake(waiting)
  end

  state.iter = function(alive)
    return function()
      if not alive() then
        return nil
      end

      if vim.tbl_isempty(queued) then
        wait()
      end

      if not alive() then
        return nil
      end

      return drain()
    end
  end

  return state
end

return M
