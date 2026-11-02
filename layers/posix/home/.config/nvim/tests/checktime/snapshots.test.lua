local T = require "tests.lib"

for _, case in ipairs {
  { "UTF-8 BOM", "\239\187\191dogs\n", "utf-8", "dogs", true },
  { "Latin-1", "caf\233\n", "latin1", "café", true },
  { "DOS", "dogs\r\nsmall dogs\r\n", "utf-8", "dogs\nsmall dogs", true },
  { "final newline", "dogs\n", "utf-8", "dogs", true },
  { "final empty record", "dogs\n\n", "utf-8", "dogs\n", true },
  { "unterminated", "dogs", "utf-8", "dogs", false },
} do
  T.test({ "read " .. case[1] }, function()
    local util = require "goto.fs_reconcile.util"
    local path = T.file {}
    local stream = assert(io.open(path, "wb"))
    assert(stream:write(case[2]))
    assert(stream:close())
    vim.opt.fileencodings = { case[3] }
    vim.cmd.edit(path)
    local observed = assert(util.read_file(0, path))
    T.eq(case[4], observed.text)
    T.eq(case[5], observed.endofline)
    assert(util.same_buffer(util.buffer(0), observed))
    assert(util.unchanged(path, observed))
  end)
end

T.test({ "reject a file changed during its read" }, function()
  local util = require "goto.fs_reconcile.util"
  local path = T.file { "dogs" }
  vim.cmd.edit(path)
  local readblob = vim.fn.readblob
  T.patch(vim.fn, "readblob", function(name)
    local value = readblob(name)
    vim.fn.writefile({ "small dogs" }, name)
    return value
  end)
  local value, state = util.read_file(0, path)
  T.eq(nil, value)
  T.eq(util.READ.UNSTABLE, state)
end)

T.test({ "missing opaque and hidden snapshots" }, function()
  local util = require "goto.fs_reconcile.util"
  local path = T.file { "dogs" }
  vim.cmd.edit(path)
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd.enew()
  T.eq("dogs", assert(util.read_file(buf, path)).text)
  local missing = assert(util.read_file(buf, path .. ".missing"))
  T.eq(nil, missing.version)
  T.eq("", missing.text)
  for _, opaque in ipairs { T.tempdir(), path } do
    if opaque == path then
      vim.fn.writefile({ string.rep("x", 2 * 1024 * 1024 + 1) }, path, "b")
    end
    local value, state = util.read_file(buf, opaque)
    T.eq(nil, value)
    T.eq(util.READ.OPAQUE, state)
  end
end)

T.test({ "poller observes truncation and closes repeatedly" }, function()
  local async = require "goto.async"
  local util = require "goto.fs_reconcile.util"
  local path = T.file { "dogs" }
  local changed = 0
  local poller = assert(util.poller(path, 10, function()
    changed = changed + 1
  end))
  T.cleanup(poller.close)
  T.eventually(function()
    return changed == 1
  end)
  vim.fn.writefile({}, path)
  T.eventually(function()
    return changed == 2
  end)
  poller.close()
  poller.close()
  async.sleep(30)
  local before = changed
  vim.fn.writefile({ "small dogs" }, path)
  async.sleep(30)
  T.eq(before, changed)
end)
