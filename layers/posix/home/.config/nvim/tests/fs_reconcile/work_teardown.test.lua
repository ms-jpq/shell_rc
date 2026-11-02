local T = require "tests.lib"

T.test({ "work teardown", timeout = 10000 }, function()
  local async = require "goto.async"
  local result = async.work(function(value)
    return value .. " work"
  end, "async")
  T.eq("async work", result)
end)
