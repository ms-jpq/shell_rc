local async = require "go.async"

local M = {}

M.new = function(timeout)
  local queued, waiting = {}, nil
  local needs_wall = false

  local state = {}

  local wake = function()
    if waiting then
      vim.schedule(waiting.resolve)
      waiting = nil
    end
  end

  local wait = function()
    waiting = async.future()
    vim.defer_fn(wake, timeout)
    waiting.await()
  end

  local drain = function()
    local q, wall = queued, needs_wall
    queued, needs_wall = {}, false

    return q, wall
  end

  state.queue_change = function(buf, name, reason)
    queued[buf] = { name = name, reason = reason }
    wake()
  end

  state.queue_wall = function()
    needs_wall = true
    wake()
  end

  state.iter = function(alive)
    return function()
      if not alive() then
        return nil
      end

      if vim.tbl_isempty(queued) and not needs_wall then
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
