local T = require "tests.lib"

local suite = function(code)
  local directory = T.tempdir()
  local file = vim.fs.joinpath(directory, "fixture.test.lua")
  assert(vim.fn.writefile(vim.split('local T = require "tests.lib"\n' .. code, "\n", { plain = true }), file) == 0)
  return directory
end

local output = function(result)
  return (result.stdout or "") .. (result.stderr or "")
end

local run = function(directory, arguments)
  local argv = {
    vim.v.progpath,
    "--headless",
    "-u",
    "NONE",
    "-i",
    "NONE",
    "-n",
    "-l",
    vim.fs.joinpath(T.root, "test.lua"),
    "--directory",
    directory,
  }
  vim.list_extend(argv, arguments or {})
  return T.process(argv, {
    timeout = 15000,
    cwd = T.repo,
    env = { NVIM_TEST_WORKER = "", NVIM_TEST_FILE = "", NVIM_TEST_CASE = "", NVIM_TEST_TIMEOUT = "" },
  })
end

local passed = function(result, count)
  assert(result.code == 0, output(result))
  assert(string.find(output(result), string.format("%d/%d passed", count, count), 1, true), output(result))
end

local order = function(result)
  local names = {}
  for line in string.gmatch(output(result), "[^\r\n]+") do
    local name = string.match(line, "PASS%s+[%d.]+ ms (.+)$")
    if name then
      table.insert(names, name)
    end
  end
  return names
end

T.test({ "the Neovim helper reports Lua errors as process failures" }, function()
  local result = T.nvim { code = 'error("helper fixture failure")', timeout = 1000 }
  assert(result.code == 1, output(result))
  assert(string.find(output(result), "helper fixture failure", 1, true), output(result))
end)

T.test({ "process deadlines kill blocked children and leave successful exits unchanged" }, function()
  local argv = { vim.v.progpath, "--headless", "-u", "NONE", "-i", "NONE", "-n", "-c" }
  local completed = T.process(
    vim.list_extend(vim.deepcopy(argv), { [[lua io.stdout:write("dogs"); vim.cmd("qa!")]] }),
    { timeout = 1000 }
  )
  T.eq(0, completed.code)
  T.eq(0, completed.signal)
  T.eq("dogs", completed.stdout)
  local blocked = T.process(vim.list_extend(argv, { "lua while true do end" }), { timeout = 100 })
  T.eq(124, blocked.code)
  T.eq(9, blocked.signal)
end)

T.test({ "process deadlines terminate descendants holding output pipes" }, function()
  local started = vim.uv.hrtime()
  local result = T.process({ "sh", "-c", "sleep 5 & wait" }, { timeout = 100 })
  local elapsed = (vim.uv.hrtime() - started) / 1e6
  T.eq(124, result.code)
  T.eq(9, result.signal)
  assert(elapsed < 2000, string.format("descendant kept output pipes open for %.0f ms", elapsed))
end)

for _, case in ipairs {
  { "patches restore values after success", "", 0 },
  { "patches restore values after test errors", 'error("patch fixture failure")', 1 },
  {
    "patches restore values despite another cleanup failing",
    'T.cleanup(function() error("cleanup fixture failure") end)',
    1,
  },
} do
  T.test({ case[1], timeout = 20000 }, function()
    local record = T.file()
    local directory = suite(string.format(
      [[
T.test({ "worker" }, function()
  local target = { present = "dogs" }
  T.cleanup(function()
    T.eq("dogs", target.present)
    T.eq(nil, target.absent)
    assert(vim.fn.writefile({ "restored" }, %q) == 0)
  end)
  T.patch(target, "present", "lil")
  T.patch(target, "present", "wang")
  T.patch(target, "absent", "new")
  T.eq("wang", target.present)
  T.eq("new", target.absent)
  %s
end)
]],
      record,
      case[2]
    ))
    local result = run(directory)
    assert(result.code == case[3], output(result))
    T.eq({ "restored" }, vim.fn.readfile(record))
  end)
end

T.test({ "worker registration errors fail without waiting for the deadline", timeout = 20000 }, function()
  local directory = suite [[
if vim.env.NVIM_TEST_WORKER == "1" then
  error("registration fixture failure")
end
T.test({ "worker" }, function() end)
]]
  local result = run(directory, { "--timeout", "5000" })
  assert(result.code == 1, output(result))
  assert(string.find(output(result), "registration fixture failure", 1, true), output(result))
  assert(not string.find(output(result), "exit=124", 1, true), output(result))
end)

for _, callback in ipairs {
  { "scheduled", "vim.schedule(fail)" },
  { "deferred", "vim.defer_fn(fail, 0)" },
} do
  T.test({ callback[1] .. " callback errors fail the worker", timeout = 20000 }, function()
    local directory = suite(string.format(
      [[
T.test({ "worker" }, function()
  local called = false
  local fail = function()
    called = true
    error("callback fixture failure")
  end
  %s
  T.eventually(function() return called end)
end)
]],
      callback[2]
    ))
    local result = run(directory, { "--timeout", "5000" })
    assert(result.code == 1, output(result))
    assert(string.find(output(result), "callback fixture failure", 1, true), output(result))
    assert(not string.find(output(result), "exit=124", 1, true), output(result))
  end)
end

T.test({ "selectors match names literally and listing does not execute tests", timeout = 20000 }, function()
  local directory = suite [[
T.test({ "dogs[1]" }, function() end)
T.test({ "dogs1" }, function() error("unselected test ran") end)
]]
  local listed = run(directory, { "--list", "dogs" })
  T.eq(0, listed.code)
  assert(string.find(output(listed), "dogs[1]", 1, true), output(listed))
  assert(string.find(output(listed), "dogs1", 1, true), output(listed))
  local by_file = run(directory, { "--list", "fixture.test.lua" })
  assert(by_file.code == 0, output(by_file))
  assert(string.find(output(by_file), "dogs[1]", 1, true), output(by_file))
  assert(string.find(output(by_file), "dogs1", 1, true), output(by_file))
  passed(run(directory, { "dogs[1]" }), 1)
  local missing = run(directory, { "no such dog" })
  assert(missing.code ~= 0, output(missing))
  assert(string.find(output(missing), "no tests match", 1, true), output(missing))
end)

T.test({ "a seed reproduces the shuffled execution order", timeout = 20000 }, function()
  local directory = suite [[
for index = 1, 8 do
  T.test({ "dog " .. index }, function() end)
end
]]
  local first = run(directory, { "--seed", "17", "--jobs", "1", "--verbose" })
  local second = run(directory, { "--seed", "17", "--jobs", "1", "--verbose" })
  local other = run(directory, { "--seed", "23", "--jobs", "1", "--verbose" })
  for _, result in ipairs { first, second, other } do
    passed(result, 8)
    T.eq(8, #order(result))
  end
  T.eq(order(first), order(second))
  assert(not vim.deep_equal(order(first), order(other)), "different seeds produced the same order")
end)

T.test({ "parallel workers can rendezvous before either finishes", timeout = 20000 }, function()
  local directory = T.tempdir()
  local fixture = suite(string.format(
    [[
local directory = %q
for index = 1, 2 do
  T.test({ "worker " .. index }, function()
    assert(vim.fn.writefile({ "ready" }, vim.fs.joinpath(directory, tostring(index))) == 0)
    T.eventually(function()
      return vim.uv.fs_stat(vim.fs.joinpath(directory, tostring(3 - index))) ~= nil
    end, { timeout = 2000 })
  end)
end
]],
    directory
  ))
  passed(run(fixture, { "--jobs", "2", "--seed", "17" }), 2)
end)

T.test({ "workers do not share globals or state directories", timeout = 20000 }, function()
  local directory = T.tempdir()
  local fixture = suite(string.format(
    [[
local directory = %q
for index = 1, 2 do
  T.test({ "worker " .. index }, function()
    assert(_G.runner_fixture_state == nil, "another test leaked its global state")
    _G.runner_fixture_state = true
    assert(vim.fn.writefile({ vim.env.XDG_STATE_HOME, tostring(vim.fn.getpid()) },
      vim.fs.joinpath(directory, tostring(index))) == 0)
  end)
end
]],
    directory
  ))
  passed(run(fixture, { "--jobs", "1" }), 2)
  local first = vim.fn.readfile(vim.fs.joinpath(directory, "1"))
  local second = vim.fn.readfile(vim.fs.joinpath(directory, "2"))
  assert(first[1] ~= second[1], "workers reused their state directory")
  assert(first[2] ~= second[2], "workers reused their process")
  for _, record in ipairs { first, second } do
    T.eq(nil, vim.uv.fs_stat(vim.fs.dirname(record[1])))
  end
end)

for _, case in ipairs {
  { "successful workers clean their resources", "", 0 },
  { "assertion failures fail the run and clean resources", 'error("fixture failure")', 1, "fixture failure" },
  {
    "errors after yielding fail the run and clean resources",
    'require("goto.async").sleep(1); error("delayed fixture failure")',
    1,
    "delayed fixture failure",
  },
  { "nonzero worker exits fail the run and clean resources", "os.exit(17)", 1, "exit=17" },
  { "blocked workers are killed and their resources are removed", "while true do end", 1, "exit=124" },
} do
  T.test({ case[1], timeout = 20000 }, function()
    local record = T.file()
    local directory = suite(string.format(
      [[
T.test({ "worker" }, function()
  local directory = T.tempdir()
  assert(vim.fn.writefile({ directory, vim.fs.dirname(vim.env.XDG_STATE_HOME), tostring(vim.fn.getpid()) }, %q) == 0)
  assert(vim.fn.writefile({ "dogs" }, vim.fs.joinpath(directory, "resource")) == 0)
  %s
end)
]],
      record,
      case[2]
    ))
    local timed_out = false
    T.cleanup(function()
      if timed_out then
        local resources = vim.fn.readfile(record)
        if resources[3] then
          local pid = assert(tonumber(resources[3]))
          assert(pid > 0 and pid == math.floor(pid), "invalid worker PID")
          vim.uv.kill(math.floor(pid), 9)
        end
      end
    end)
    local arguments = case[2] == "while true do end" and { "--timeout", "2000" } or {}
    local result = run(directory, arguments)
    timed_out = result.code == 124
    assert(result.code == case[3], output(result))
    if case[4] then
      assert(string.find(output(result), case[4], 1, true), output(result))
    end
    local resources = vim.fn.readfile(record)
    T.eq(3, #resources)
    for index = 1, 2 do
      T.eq(nil, vim.uv.fs_stat(resources[index]))
    end
  end)
end
