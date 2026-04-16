local new_queue = require "go.async.queue"
local budget = 64

return function()
  local queue = new_queue()

  local step = function()
    local thread = queue.pop()
    local ok, err = coroutine.resume(thread)

    if not ok then
      local tb = debug.traceback(thread, err)
      vim.notify(tb, vim.log.levels.ERROR)
    elseif coroutine.status(thread) ~= "dead" then
      queue.push(thread)
    end
  end

  local drain
  drain = function()
    for _ = 1, math.min(queue.len(), budget) do
      step()
    end

    if queue.len() > 0 then
      vim.schedule(drain)
    end
  end

  local schedule = function(fn)
    local thread = type(fn) == "thread" and fn or coroutine.create(fn)
    local was_empty = queue.len() == 0

    queue.push(thread)
    if was_empty then
      vim.schedule(drain)
    end
  end

  return {
    schedule = schedule,
    step = step,
    drain = drain,
  }
end
