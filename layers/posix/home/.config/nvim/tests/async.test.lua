local T = require "tests.lib"
local async = require "goto.async"
local queue = require "goto.queue"

local channel = function()
  local value = queue.mpsc()
  T.cleanup(value.close)
  return value
end

T.test({ "MPSC preserves message order and accepts false but rejects nil" }, function()
  local messages = channel()
  assert(messages.send "lil")
  assert(messages.send "wang")
  assert(messages.send(false))
  T.eq("lil", messages())
  T.eq("wang", messages())
  T.eq(false, messages.wait(1))
  T.eq(false, messages())
  assert(not pcall(messages.send, nil))
end)

T.test({ "MPSC receives a message sent after the consumer blocks" }, function()
  local messages = channel()
  vim.schedule(function()
    assert(messages.send "dog")
  end)
  T.eq("dog", messages())
end)

T.test({ "MPSC wait reports timeout only while the channel remains empty" }, function()
  local messages = channel()
  T.eq(true, messages.wait(1))
  vim.schedule(function()
    assert(messages.send "dog")
  end)
  T.eq(false, messages.wait(1000))
  T.eq("dog", messages())
end)

T.test({ "MPSC wakes a waiting poll when closed" }, function()
  local messages = channel()
  vim.schedule(messages.close)
  T.eq(false, messages.wait(1000))
end)

T.test({ "MPSC accepts ordered messages from multiple producers" }, function()
  local messages = channel()
  local sent = {}
  for _, name in ipairs { "lil", "wang" } do
    async.run(function()
      async.scheduled()
      table.insert(sent, name)
      assert(messages.send(name))
    end)
  end
  local received = { messages(), messages() }
  T.eq(2, #received)
  T.eq(sent, received)
end)

T.test({ "MPSC rejects a second blocked consumer" }, function()
  local messages = channel()
  async.run(function()
    messages()
  end)
  assert(not pcall(function()
    async.run(function()
      messages()
    end)
  end))
end)

T.test({ "closing MPSC discards queued messages and rejects further sends" }, function()
  local messages = channel()
  assert(messages.send "discard")
  messages.close()
  T.eq(nil, messages())
  T.eq(false, messages.wait(1))
  T.eq(false, messages.send "dog")
  assert(not pcall(messages.send, nil))
end)

T.test({ "closing MPSC wakes a blocked receiver" }, function()
  local messages = channel()
  vim.schedule(messages.close)
  T.eq(nil, messages())
end)
