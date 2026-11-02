local T = require "tests.lib"

T.test({ "work group", timeout = 10000 }, function()
  local async = require "goto.async"
  assert(vim.deep_equal(async.all {}, {}))

  local work = async.work
  local started, finished = 0, 0
  T.patch(async, "work", function(...)
    started = started + 1
    local result = work(...)
    assert(started == 3, "all jobs must be submitted before awaiting results")
    finished = finished + 1
    return result
  end)
  local tasks = vim
    .iter({ { "dog", 30 }, { false, 0 }, { "puppy", 10 } })
    :map(function(args)
      return function()
        return async.work(function(value, delay)
          vim.uv.sleep(delay)
          return value
        end, unpack(args))
      end
    end)
    :totable()
  local results = async.all(tasks)
  assert(vim.deep_equal(results, { "dog", false, "puppy" }), vim.inspect(results))
  assert(finished == 3)
  async.work = work

  local completed = false
  T.patch(async, "work", function(...)
    local result = work(...)
    completed = true
    return result
  end)
  local ok, err = pcall(async.all, {
    function()
      return async.work(function()
        error "region failure"
      end)
    end,
    function()
      return async.work(function()
        vim.uv.sleep(50)
        return "finished"
      end)
    end,
  })
  async.work = work
  assert(not ok and type(err) == "string" and string.find(err, "region failure", 1, true), tostring(err))
  assert(completed, "worker failure must not leave siblings unjoined")

  assert(vim.deep_equal(
    async.all {
      function()
        return async.work(function()
          return "recovered"
        end)
      end,
    },
    { "recovered" }
  ))
end)
