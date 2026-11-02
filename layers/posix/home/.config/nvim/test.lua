#!/usr/bin/env -S -- nvim -l

local root = vim.fs.dirname(vim.fs.abspath(string.sub(debug.getinfo(1, "S").source, 2)))
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(vim.fs.joinpath(root, "pack/local/start/goto"))

local T = require "tests.lib"
local async = require "goto.async"

local report = function(message)
  io.stdout:write(message .. "\n")
  io.stdout:flush()
end

local worker = function()
  local schedule, defer = vim.schedule, vim.defer_fn
  local finished = false
  local finish = function(ok, err)
    if finished then
      return
    end
    finished = true
    local clean, cleanup_error = pcall(T.close)
    schedule(function()
      if not ok or not clean then
        io.stderr:write(tostring(err or cleanup_error) .. "\n")
        vim.cmd "cquit 1"
      else
        vim.cmd "qa!"
      end
    end)
  end
  local guarded = function(fn)
    return function()
      local ok, err = xpcall(fn, debug.traceback)
      if not ok then
        finish(false, err)
      end
    end
  end
  T.patch(vim, "schedule", function(fn)
    schedule(guarded(fn))
  end)
  T.patch(vim, "defer_fn", function(fn, timeout)
    return defer(guarded(fn), timeout)
  end)
  async.run(function()
    local ok, err = xpcall(function()
      T.load(assert(vim.env.NVIM_TEST_FILE))
      local entry = vim.iter(T.entries):find(function(candidate)
        return candidate.name == vim.env.NVIM_TEST_CASE
      end)
      assert(entry, "unknown worker test: " .. tostring(vim.env.NVIM_TEST_CASE))
      entry.fn()
      async.scheduled()
    end, debug.traceback)
    finish(ok, err)
  end)
end

local parse = function(args)
  local options = { seed = os.time(), jobs = 0, filters = {}, list = false, verbose = false }
  local index = 1
  while index <= #args do
    local value = args[index]
    if value == "--directory" then
      index = index + 1
      options.directory = vim.fs.abspath(assert(args[index], value .. " requires a directory"))
    elseif value == "--seed" or value == "--jobs" or value == "--timeout" then
      index = index + 1
      local number = assert(tonumber(args[index]), value .. " requires a number")
      assert(number >= 0 and number % 1 == 0, value .. " requires a nonnegative integer")
      options[string.sub(value, 3)] = math.floor(number)
    elseif value == "--list" then
      options.list = true
    elseif value == "--verbose" then
      options.verbose = true
    elseif value == "--help" then
      report "Usage: test.lua [--seed N] [--jobs N] [--timeout MS] [--directory DIR] [--list] [--verbose] [name ...]"
      report "Names match paths or test names literally. --jobs 0 runs all selected tests concurrently."
      return
    elseif value == "--" then
      vim.list_extend(options.filters, vim.list_slice(args, index + 1))
      break
    else
      assert(not vim.startswith(value, "--"), "unknown option: " .. value)
      table.insert(options.filters, value)
    end
    index = index + 1
  end
  return options
end

local invoke = function(entry, timeout)
  if entry.isolate then
    local directory = T.tempdir()
    local result = T.nvim {
      args = { "-c", "lua dofile(vim.env.NVIM_TEST_RUNNER)" },
      cwd = T.repo,
      timeout = timeout,
      env = {
        NVIM_TEST_FILE = entry.file,
        NVIM_TEST_CASE = entry.name,
        NVIM_TEST_WORKER = "1",
        NVIM_TEST_RUNNER = vim.fs.joinpath(root, "test.lua"),
        XDG_CONFIG_HOME = vim.fs.joinpath(directory, "config"),
        XDG_CACHE_HOME = vim.fs.joinpath(directory, "cache"),
        XDG_DATA_HOME = vim.fs.joinpath(directory, "data"),
        XDG_STATE_HOME = vim.fs.joinpath(directory, "state"),
        TMPDIR = directory,
      },
    }
    local output = (result.stdout or "") .. (result.stderr or "")
    assert(
      result.code == 0 and result.signal == 0,
      string.format("exit=%d signal=%d\n%s", result.code, result.signal, output)
    )
  else
    local future = async.future()
    local done = false
    local finish = function(ok, err)
      if not done then
        done = true
        future.resolve(ok, err)
      end
    end
    local timer = vim.defer_fn(function()
      finish(false, "timeout")
    end, timeout)
    async.run(function()
      finish(xpcall(entry.fn, debug.traceback))
    end)
    local ok, err = future.await()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    assert(ok, err)
  end
end

local run = function(options)
  local files = vim.fn.globpath(options.directory or vim.fs.joinpath(root, "tests"), "**/*.test.lua", false, true)
  table.sort(files)
  for _, file in ipairs(files) do
    T.load(file)
  end
  local selected = vim
    .iter(T.entries)
    :filter(function(entry)
      return #options.filters == 0
        or vim.iter(options.filters):any(function(filter)
          return string.find(entry.name, filter, 1, true) ~= nil
        end)
    end)
    :totable()
  assert(#selected > 0, "no tests match the selection")
  if options.list then
    for _, entry in ipairs(selected) do
      report(entry.name)
    end
    return 0
  end
  math.randomseed(options.seed)
  for index = #selected, 2, -1 do
    local other = math.random(index)
    selected[index], selected[other] = selected[other], selected[index]
  end
  report(string.format("seed=%d tests=%d jobs=%d", options.seed, #selected, options.jobs))
  local started = vim.uv.hrtime()
  local next_index = 1
  local failures = {}
  local results = {}
  local limit = options.jobs == 0 and #selected or math.min(options.jobs, #selected)
  local workers = {}
  for _ = 1, limit do
    table.insert(workers, function()
      while selected[next_index] do
        local entry = selected[next_index]
        next_index = next_index + 1
        local begin = vim.uv.hrtime()
        local ok, err = xpcall(function()
          invoke(entry, options.timeout or entry.timeout)
        end, debug.traceback)
        local elapsed = (vim.uv.hrtime() - begin) / 1e6
        table.insert(results, { name = entry.name, elapsed = elapsed })
        if not ok then
          table.insert(failures, entry.name)
          io.stderr:write("FAIL " .. entry.name .. "\n" .. tostring(err) .. "\n")
        elseif options.verbose then
          report(string.format("PASS %7.1f ms %s", elapsed, entry.name))
        end
      end
    end)
  end
  local done, failure = false, nil
  async.run(function()
    local ok, err = xpcall(function()
      async.all(workers)
    end, debug.traceback)
    failure = not ok and err or nil
    done = true
  end)
  assert(
    vim.wait(2147483647, function()
      return done
    end, 10),
    "runner interrupted"
  )
  assert(not failure, failure)
  T.close()
  table.sort(results, function(left, right)
    return left.elapsed > right.elapsed
  end)
  report(string.format("%d/%d passed in %.2fs", #selected - #failures, #selected, (vim.uv.hrtime() - started) / 1e9))
  for _, result in ipairs(vim.list_slice(results, 1, 5)) do
    report(string.format("%7.1f ms %s", result.elapsed, result.name))
  end
  return #failures == 0 and 0 or 1
end

if vim.env.NVIM_TEST_WORKER == "1" then
  worker()
else
  local ok, code = xpcall(function()
    local options = parse(arg)
    return options and run(options) or 0
  end, debug.traceback)
  if not ok then
    io.stderr:write(tostring(code) .. "\n")
    local clean, err = pcall(T.close)
    if not clean then
      io.stderr:write(tostring(err) .. "\n")
    end
  end
  os.exit(ok and code or 1)
end
