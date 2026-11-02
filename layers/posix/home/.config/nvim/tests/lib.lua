local async = require "goto.async"

local M = {}

M.root = vim.fs.dirname(vim.fs.dirname(string.sub(debug.getinfo(1, "S").source, 2)))
M.repo = vim.fs.normalize(vim.fs.joinpath(M.root, "../../../../.."))
M.entries = {}
M.resources = {}

---@class TestSpec
---@field [1] string
---@field timeout? integer
---@field isolate? boolean

---@param expected any
---@param actual any
---@param context? any
M.eq = function(expected, actual, context)
  assert(vim.deep_equal(expected, actual), vim.inspect { expected = expected, actual = actual, context = context })
end

---@param predicate fun(): boolean
---@param options? { timeout?: integer, interval?: integer, message?: fun(): string }
M.eventually = function(predicate, options)
  options = options or {}
  local timeout = options.timeout or 2000
  local deadline = vim.uv.hrtime() + timeout * 1e6
  repeat
    if predicate() then
      return
    end
    async.sleep(options.interval or 10)
  until vim.uv.hrtime() >= deadline
  if not predicate() then
    error(options.message and options.message() or string.format("condition did not become true within %d ms", timeout))
  end
end

---@param cleanup fun()
M.cleanup = function(cleanup)
  table.insert(M.resources, cleanup)
end

---@param target table
---@param key string
---@param value any
M.patch = function(target, key, value)
  local original = target[key]
  rawset(target, key, value)
  M.cleanup(function()
    rawset(target, key, original)
  end)
end

M.close = function()
  local failures = {}
  for index = #M.resources, 1, -1 do
    local ok, err = pcall(M.resources[index])
    if not ok then
      table.insert(failures, tostring(err))
    end
  end
  M.resources = {}
  assert(#failures == 0, table.concat(failures, "\n"))
end

---@return string
M.tempdir = function()
  local directory = vim.fn.tempname()
  assert(vim.fn.mkdir(directory, "p") == 1, directory)
  M.cleanup(function()
    assert(vim.fn.delete(directory, "rf") == 0, directory)
  end)
  return directory
end

---@param lines? string[]
---@return string
M.file = function(lines)
  local path = vim.fs.joinpath(M.tempdir(), "file")
  assert(vim.fn.writefile(lines or {}, path) == 0, path)
  return path
end

---@param argv string[]
---@param options? vim.SystemOpts
---@return vim.SystemCompleted
M.process = function(argv, options)
  local future = async.future()
  local opts = vim.tbl_extend("force", { text = true, timeout = 5000 }, options or {})
  local timeout = opts.timeout
  opts.timeout = nil
  opts.detach = true
  opts.env = vim.tbl_extend("force", {
    NVIM_TEST_WORKER = "",
    NVIM_TEST_FILE = "",
    NVIM_TEST_CASE = "",
    NVIM_TEST_TIMEOUT = "",
  }, opts.env or {})
  local process = vim.system(argv, opts, vim.schedule_wrap(future.resolve))
  local running, timed_out = true, false
  local timer = vim.defer_fn(function()
    if running then
      timed_out = true
      vim.uv.kill(-process.pid, 9)
    end
  end, timeout)
  M.cleanup(function()
    if running then
      vim.uv.kill(-process.pid, 9)
    end
  end)
  local result = future.await()
  running = false
  if not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  if timed_out then
    result.code = 124
  end
  return result
end

---@param options { code?: string, args?: string[], timeout?: integer, cwd?: string, env?: table<string,string>, stdin?: string }
---@return vim.SystemCompleted
M.nvim = function(options)
  local argv = { vim.v.progpath, "--headless", "-u", "NONE", "-i", "NONE", "-n" }
  vim.list_extend(argv, options.args or {})
  if options.code then
    local script = vim.fs.joinpath(M.tempdir(), "main.lua")
    assert(vim.fn.writefile(vim.split(options.code, "\n", { plain = true }), script) == 0)
    local command = string.format(
      "lua local ok, err = xpcall(function() dofile(%q) end, debug.traceback); if not ok then io.stderr:write(tostring(err)); vim.cmd('cquit 1') else vim.cmd('qa!') end",
      script
    )
    vim.list_extend(argv, { "-c", command })
  end
  return M.process(
    argv,
    { timeout = options.timeout or 5000, cwd = options.cwd, env = options.env, stdin = options.stdin }
  )
end

---@param spec TestSpec
---@param fn fun()
M.test = function(spec, fn)
  assert(type(spec[1]) == "string" and spec[1] ~= "", "test requires a name")
  assert(type(fn) == "function", spec[1] .. ": test requires a function")
  local file = assert(M.loading, "register tests while loading a suite")
  local relative = vim.startswith(file, M.root .. "/") and string.sub(file, #M.root + 2) or file
  local name = relative .. " :: " .. spec[1]
  for _, entry in ipairs(M.entries) do
    assert(entry.name ~= name, "duplicate test: " .. name)
  end
  table.insert(M.entries, {
    name = name,
    file = file,
    fn = fn,
    timeout = spec.timeout or 10000,
    isolate = spec.isolate ~= false,
  })
end

---@param spec TestSpec
---@param body fun(test: fun(spec: TestSpec, fn: fun()))
M.describe = function(spec, body)
  body(function(child, fn)
    local merged = vim.tbl_extend("force", spec, child)
    merged[1] = spec[1] .. " / " .. child[1]
    ---@cast merged TestSpec
    M.test(merged, fn)
  end)
end

---@param file string
M.load = function(file)
  M.loading = file
  local ok, err = xpcall(function()
    dofile(file)
  end, debug.traceback)
  M.loading = nil
  assert(ok, err)
end

return M
