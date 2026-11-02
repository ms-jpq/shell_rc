local T = require "tests.lib"

local lines = function(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, true)
end

local replace = function(buf, target, mark)
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"
  local plan = hunks.plan(util.buffer(buf), { text = table.concat(target, "\n"), endofline = true })
  hunks.apply(buf, plan, mark or function() end)
end

local native_replace = function(buf, before, after)
  if #after == 1 and after[1] == "" then
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
    return
  elseif #before == 1 and before[1] == "" then
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, after)
    return
  end
  local changes = vim.text.diff(table.concat(before, "\n") .. "\n", table.concat(after, "\n") .. "\n", {
    result_type = "indices",
  })
  assert(type(changes) == "table")
  ---@cast changes integer[][]
  for _, change in ipairs(vim.fn.reverse(changes)) do
    local old_start, old_count, new_start, new_count = unpack(change)
    local start = old_start - (old_count == 0 and 0 or 1)
    vim.api.nvim_buf_set_lines(
      buf,
      start,
      start + old_count,
      true,
      vim.list_slice(after, new_start, new_start + new_count - 1)
    )
  end
end

local mark_positions = function(buf, positions)
  local namespace = vim.api.nvim_create_namespace "test-hunk-affinity"
  local ids = {}
  for _, position in ipairs(positions) do
    table.insert(ids, vim.api.nvim_buf_set_extmark(buf, namespace, position[1], position[2], { right_gravity = true }))
  end
  return function()
    return vim
      .iter(ids)
      :map(function(id)
        return vim.api.nvim_buf_get_extmark_by_id(buf, namespace, id, {})
      end)
      :totable()
  end
end

T.test({ "narrow replacement retains native extmark affinity" }, function()
  local state = 1
  local random = function(limit)
    state = (state * 48271) % 2147483647
    return state % limit + 1
  end
  local random_lines = function()
    local result = {}
    for _ = 1, random(5) do
      local row = {}
      for _ = 1, random(5) - 1 do
        table.insert(row, string.char(string.byte "a" + random(4) - 1))
      end
      table.insert(result, table.concat(row))
    end
    return result
  end
  local cases = {
    { { "dog" }, { "lil", "wang" } },
    { { "one", "two", "three" }, { "zero", "one", "two", "three" } },
    { { "one", "two", "three", "four" }, { "ONE", "two", "three", "FOUR", "five" } },
  }
  for _ = 1, 24 do
    table.insert(cases, { random_lines(), random_lines() })
  end
  for _, case in ipairs(cases) do
    local before, after = unpack(case)
    local positions = {}
    for row, line in ipairs(before) do
      for col = 0, #line do
        table.insert(positions, { row - 1, col })
      end
    end
    local expected = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(expected, 0, -1, true, before)
    local expected_marks = mark_positions(expected, positions)
    native_replace(expected, before, after)
    local actual = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(actual, 0, -1, true, before)
    local actual_marks = mark_positions(actual, positions)
    replace(actual, after)
    T.eq(after, lines(actual))
    assert(
      vim.deep_equal(expected_marks(), actual_marks()),
      vim.inspect {
        before = before,
        after = after,
        expected = expected_marks(),
        actual = actual_marks(),
      }
    )
    vim.api.nvim_buf_delete(expected, { force = true })
    vim.api.nvim_buf_delete(actual, { force = true })
  end
end)

T.test({ "replacement forms one undo entry after the local edit" }, function()
  local before = { "dog", "lil", "wang", "end" }
  vim.cmd.edit(T.file(before))
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 1, 2, true, { "small lil" })
  local local_lines = lines(buf)
  replace(buf, { "dog", "small lil", "big wang", "end", "again" })
  vim.cmd.undo()
  T.eq(local_lines, lines(buf))
  vim.cmd.undo()
  T.eq(before, lines(buf))
end)

T.test({ "replacement preserves the current window when updating another buffer" }, function()
  vim.cmd.vsplit()
  local target, source = unpack(vim.api.nvim_list_wins())
  local tracked = vim.api.nvim_create_buf(true, false)
  local current = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(tracked, 0, -1, true, { "lil", "wang" })
  vim.api.nvim_buf_set_lines(current, 0, -1, true, { "dog" })
  vim.api.nvim_win_set_buf(target, tracked)
  vim.api.nvim_win_set_buf(source, current)
  vim.api.nvim_set_current_win(source)
  replace(tracked, { "dog", "lil", "wang" })
  T.eq(source, vim.api.nvim_get_current_win())
  T.eq(current, vim.api.nvim_get_current_buf())
  T.eq({ "dog", "lil", "wang" }, lines(tracked))
end)

T.test({ "replacement marks each changed range" }, function()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "dog", "lil", "wang", "end" })
  local ranges = {}
  replace(buf, { "DOG", "lil", "wang", "END" }, function(start, finish)
    table.insert(ranges, { start, finish })
  end)
  T.eq({ { 3, 4 }, { 0, 1 } }, ranges)
end)

T.test({ "record patches reconstruct every small source and target" }, function()
  local diff = require "goto.fs_reconcile.hunks.diff"
  local texts = { "", "dog", "dog\n", "dog\n\n", "犬\nlil", "\nlil\nwang" }
  for _, before in ipairs(texts) do
    for _, after in ipairs(texts) do
      local records = diff.records(before)
      for _, hunk in ipairs(vim.fn.reverse(diff.plan(before, after))) do
        for _ = hunk.start, hunk.finish - 1 do
          table.remove(records, hunk.start + 1)
        end
        for index = #hunk.records, 1, -1 do
          table.insert(records, hunk.start + 1, hunk.records[index])
        end
      end
      T.eq(after, string.sub(table.concat(records), 1, -2))
    end
  end
end)

T.test({ "diff workers have the thread-safe Neovim helpers" }, function()
  local async = require "goto.async"
  local result = async.work(function()
    return vim.json.encode {
      changes = vim.text.diff("dogs\n", "lil\nwang\n", { result_type = "indices" }),
      helpers = { iter = type(vim.iter), list_slice = type(vim.list_slice), split = type(vim.split), fn = type(vim.fn) },
    }
  end)
  local decoded = vim.json.decode(result)
  T.eq({ { 1, 1, 1, 2 } }, decoded.changes)
  T.eq({ iter = "table", list_slice = "function", split = "function", fn = "nil" }, decoded.helpers)
end)

T.test({ "replacement keeps final empty records separate from endofline" }, function()
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"
  local buf = vim.api.nvim_get_current_buf()
  for _, fileformat in ipairs { "unix", "dos" } do
    vim.bo[buf].fileformat = fileformat
    for _, endofline in ipairs { false, true } do
      for _, before in ipairs { { "dogs" }, { "dogs", "" }, { "" } } do
        for _, after in ipairs { { "small dogs" }, { "small dogs", "" }, { "", "" }, { "" } } do
          vim.api.nvim_buf_set_lines(buf, 0, -1, true, before)
          vim.bo[buf].endofline = endofline
          local expected = { text = table.concat(after, "\n"), endofline = endofline }
          hunks.apply(buf, hunks.plan(util.buffer(buf), expected), function() end)
          T.eq(after, lines(buf))
          assert(util.same_buffer(expected, util.buffer(buf)))
          T.eq(fileformat, vim.bo[buf].fileformat)
        end
      end
    end
  end
end)
