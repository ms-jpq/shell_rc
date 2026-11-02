local T = require "tests.lib"

T.test({ "async tasks preserve results and join failures", timeout = 10000 }, function()
  local async = require "goto.async"
  local work = async.work
  T.patch(async, "work", function()
    error "joining tasks must not require workers"
  end)

  assert(vim.deep_equal(async.all {}, {}))
  local result = async.all {
    function()
      return "dog"
    end,
    function()
      return false
    end,
  }
  assert(vim.deep_equal(result, { "dog", false }), vim.inspect(result))

  local started = 0
  for _, case in ipairs { {}, { false }, { { message = "dog failure" } } } do
    local completed = false
    local ok, err = pcall(async.all, {
      function()
        async.sleep(10)
        error "later failure"
      end,
      function()
        error(case[1], 0)
      end,
      function()
        async.sleep(20)
        completed = true
        return nil
      end,
    })
    assert(not ok and err == case[1], vim.inspect { ok = ok, err = err })
    assert(completed, "the first failure must be retained until all tasks finish")
  end

  result = async.all {
    function()
      started = started + 1
      async.sleep(20)
      assert(started == 3)
      return "dog"
    end,
    function()
      started = started + 1
      return nil
    end,
    function()
      started = started + 1
      async.scheduled()
      return false
    end,
  }
  assert(result[1] == "dog" and result[2] == nil and result[3] == false, vim.inspect(result))

  for _, delayed_error in ipairs { false, true } do
    local completed = false
    local ok, err = pcall(async.all, {
      function()
        if delayed_error then
          async.scheduled()
        end
        error "task failure"
      end,
      function()
        async.sleep(20)
        completed = true
        return nil
      end,
    })
    assert(not ok and type(err) == "string" and string.find(err, "task failure", 1, true), tostring(err))
    assert(completed, "failure must join siblings, including ones not started yet")
  end

  result = async.all {
    function()
      return async.all {
        function()
          async.scheduled()
          return "puppy"
        end,
      }
    end,
    function()
      return "dog"
    end,
  }
  assert(vim.deep_equal(result, { { "puppy" }, "dog" }), vim.inspect(result))
  async.work = work
end)
