local T = require "tests.lib"

T.test({ "mpsc burst", timeout = 10000 }, function()
  local queue = require "goto.queue"
  local chan = queue.mpsc()
  for index = 1, 10 * 1024 do
    assert(chan.send(index))
  end
  for index = 1, 10 * 1024 do
    assert(chan() == index)
  end
  chan.close()
  assert(chan() == nil)
end)
