local T = require "tests.lib"
local async = require "goto.async"
local hunks = require "goto.fs_reconcile.hunks"
local util = require "goto.fs_reconcile.util"
local prefix = "so i think there is something really imporatnt, which is we"
local typo = prefix .. " have all the skilsl right?"
local corrected = prefix .. " have all the skills right?"

local open = function(lines)
  local filename = T.file(lines)
  vim.cmd.edit(filename)
  return filename
end

local attach = function()
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  async.sleep(100)
end

local converged = function(filename, expected)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected)
      and vim.deep_equal(vim.fn.readfile(filename), expected)
      and not vim.bo.modified
  end, { timeout = 3000 })
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local disk = vim.fn.readfile(filename)
  assert(
    vim.deep_equal(actual, expected) and vim.deep_equal(disk, expected) and not vim.bo.modified,
    vim.inspect { expected = expected, actual = actual, disk = disk, modified = vim.bo.modified }
  )
end

local observe_merges = function()
  local merges = {}
  local merge = hunks.merge
  T.patch(hunks, "merge", function(base, current, disk)
    table.insert(merges, { base = base.text, current = current.text, disk = disk.text })
    return merge(base, current, disk)
  end)
  return merges
end

local fail_readback = function()
  local read_file = util.read_file
  local command = vim.cmd
  local pending, failed = false, false
  T.patch(vim, "cmd", function(source)
    local result = command(source)
    if string.find(source, "noautocmd silent", 1, true) and string.find(source, "write!", 1, true) then
      pending = not failed
    end
    return result
  end)
  T.patch(util, "read_file", function(...)
    if pending then
      pending, failed = false, true
      return nil, util.READ.UNSTABLE
    end
    return read_file(...)
  end)
  return function()
    vim.cmd = command
    util.read_file = read_file
    assert(failed, "read failure was not injected")
  end
end

local own_save = function(scenario)
  return function()
    local filename = open { prefix }
    attach()
    local merges = observe_merges()
    local restore = scenario == "unreadable" and fail_readback() or nil
    local saved = false
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      buffer = 0,
      once = true,
      callback = function()
        saved = true
        vim.api.nvim_buf_set_lines(0, 0, -1, true, { corrected })
        if scenario == "post_error" then
          error "injected post-write hook failure"
        elseif scenario == "unmodifiable" then
          vim.bo.modifiable = false
          vim.defer_fn(function()
            vim.bo.modifiable = true
          end, 50)
        end
      end,
    })
    vim.api.nvim_buf_set_lines(0, 0, -1, true, { typo })
    converged(filename, { corrected })
    if restore then
      restore()
    end
    assert(saved, "no save occurred")
    assert(#merges == 0, vim.inspect(merges))
  end
end

local cases = {
  ordinary = own_save "ordinary",
  unreadable = own_save "unreadable",
  post_error = own_save "post_error",
  unmodifiable = own_save "unmodifiable",
}

cases.typing = function()
  local filename = open { "" }
  attach()
  local merges = observe_merges()
  for index, delay in ipairs { 0, 20, 100, 280, 310, 400, 650 } do
    local start = tostring(index) .. ": we have all the "
    vim.api.nvim_buf_set_lines(0, 0, -1, true, { start .. "skilsl right?" })
    async.sleep(delay)
    local expected = { start .. "skills right?" }
    vim.api.nvim_buf_set_lines(0, 0, -1, true, expected)
    converged(filename, expected)
  end
  assert(#merges == 0, vim.inspect(merges))
end

local native_write = function(scenario)
  return function()
    local filename = open { prefix }
    if scenario == "no_undo" then
      vim.bo.undolevels = -1
    end
    local posted, prepared = false, false
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      buffer = 0,
      once = true,
      callback = function()
        posted = true
        vim.api.nvim_buf_set_lines(0, 0, -1, true, { corrected })
        if scenario == "post_error" then
          error "injected native post-write hook failure"
        end
      end,
    })
    attach()
    local nested = false
    if scenario == "nested" then
      vim.api.nvim_create_autocmd({ "BufWritePre" }, {
        buffer = 0,
        once = true,
        callback = function()
          vim.schedule(function()
            nested = true
          end)
          assert(
            vim.wait(100, function()
              return nested
            end),
            "nested event loop did not run"
          )
        end,
      })
    end
    if scenario == "pre_post" then
      vim.api.nvim_create_autocmd({ "BufWritePre" }, {
        buffer = 0,
        once = true,
        callback = function()
          prepared = true
          vim.api.nvim_buf_set_lines(0, 0, -1, true, { typo })
        end,
      })
    else
      vim.api.nvim_buf_set_lines(0, 0, -1, true, { typo })
    end
    local ok, err = pcall(vim.cmd.write)
    if scenario == "post_error" then
      assert(
        not ok and string.find(tostring(err), "injected native post-write hook failure", 1, true),
        vim.inspect(err)
      )
    else
      assert(ok, err)
    end
    converged(filename, { corrected })
    assert(posted, "post-write correction was not injected")
    assert(scenario ~= "pre_post" or prepared, "pre-write change was not injected")
    assert(scenario ~= "nested" or nested, "pre-write nested event loop was not exercised")
  end
end

cases.native_write = native_write "ordinary"
cases.native_pre_post = native_write "pre_post"
cases.native_post_error = native_write "post_error"
cases.native_no_undo = native_write "no_undo"
cases.native_nested = native_write "nested"

cases.native_failed_alternate = function()
  local filename = open { prefix }
  local destination = vim.fn.tempname()
  attach()
  local merges = observe_merges()
  local prepared = false
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    once = true,
    callback = function()
      prepared = true
      error "injected native pre-write hook failure"
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { typo })
  local ok, err = pcall(vim.cmd.write)
  assert(
    prepared and not ok and string.find(tostring(err), "injected native pre-write hook failure", 1, true),
    vim.inspect(err)
  )
  assert(vim.deep_equal(vim.fn.readfile(filename), { prefix }), "failed native write changed disk")
  vim.cmd.write(destination)
  assert(vim.deep_equal(vim.fn.readfile(destination), { typo }), "alternate write did not complete")
  assert(vim.deep_equal(vim.fn.readfile(filename), { prefix }), "alternate write changed original disk")
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { corrected })
  converged(filename, { corrected })
  assert(#merges == 0, vim.inspect(merges))
  assert(vim.deep_equal(vim.fn.readfile(destination), { typo }), "reconciliation changed alternate file")
end

cases.saveas = function()
  open { prefix }
  local destination = vim.fn.tempname()
  attach()
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { typo })
  vim.cmd.saveas(destination)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { corrected })
  converged(destination, { corrected })
end

local external = function(native, unreadable)
  return function()
    local filename = open { "dog", "walk", "home" }
    local changed = false
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      buffer = 0,
      once = true,
      callback = function()
        changed = true
        assert(vim.deep_equal(vim.fn.readfile(filename), { "dog", "sniff", "walk", "home" }))
        vim.fn.writefile({ "dog", "sniff", "long walk", "home" }, filename)
        vim.api.nvim_buf_set_lines(0, 3, 4, true, { "nap" })
      end,
    })
    attach()
    local restore = unreadable and fail_readback() or nil
    vim.api.nvim_buf_set_lines(0, 1, 1, true, { "sniff" })
    if native then
      vim.cmd.write()
    end
    converged(filename, { "dog", "sniff", "long walk", "nap" })
    if restore then
      restore()
    end
    assert(changed, "post-write changes were not injected")
  end
end

cases.external = external(false)
cases.native_external = external(true)
cases.unreadable_external = external(false, true)

local write_failure = function(native)
  return function()
    local filename = open { prefix }
    attach()
    local posted, attempts = 0, 0
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      buffer = 0,
      callback = function()
        posted = posted + 1
      end,
    })
    local command = vim.cmd
    T.patch(vim, "cmd", function(source)
      if string.find(source, "write", 1, true) then
        attempts = attempts + 1
      end
      return command(source)
    end)
    vim.o.write = false
    vim.api.nvim_buf_set_lines(0, 0, -1, true, { typo })
    if native then
      local ok, err = pcall(function()
        vim.cmd "write"
      end)
      assert(not ok and string.find(tostring(err), "E142:", 1, true), vim.inspect { ok = ok, error = err })
    end
    T.eventually(function()
      return attempts > 0
    end)
    assert(attempts > 0, "write failure was not exercised")
    assert(posted == 0, "failed write emitted BufWritePost")
    assert(vim.deep_equal(vim.fn.readfile(filename), { prefix }), "failed write changed disk")
    assert(vim.bo.modified, "failed write marked buffer clean")
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { typo }), "failed write changed buffer")
    vim.api.nvim_buf_set_lines(0, 0, -1, true, { corrected })
    vim.o.write = true
    vim.cmd = command
    converged(filename, { corrected })
    assert(posted > 0, "write never recovered")
  end
end

cases.auto_failure = write_failure(false)
cases.native_failure = write_failure(true)

local names = {
  ordinary = "automatic saves acknowledge post-write corrections",
  unreadable = "automatic saves acknowledge corrections after a readback failure",
  post_error = "automatic saves recover after a failing post-write hook",
  unmodifiable = "automatic saves resume after a post-write modifiable transition",
  typing = "typing corrections across save boundaries never echo",
  native_write = "native writes preserve post-write corrections",
  native_pre_post = "native writes preserve pre-write and post-write corrections",
  native_post_error = "native writes recover after a failing post-write hook",
  native_no_undo = "native writes acknowledge saves without undo history",
  native_nested = "native writes survive a nested event loop",
  native_failed_alternate = "a failed native write followed by an alternate write preserves both files",
  saveas = "saveas acknowledges the destination before subsequent corrections",
  external = "independent disk edits survive automatic save acknowledgement",
  native_external = "independent disk edits survive native save acknowledgement",
  unreadable_external = "independent disk edits survive a readback failure",
  auto_failure = "automatic save failures preserve edits and recover",
  native_failure = "native save failures preserve edits and recover",
}

for _, name in ipairs(vim.fn.sort(vim.tbl_keys(cases))) do
  T.test({ names[name], timeout = 15000 }, cases[name])
end
