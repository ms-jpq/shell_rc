local T = require "tests.lib"

T.test({ "cursor hunks", timeout = 10000 }, function()
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"

  local base = {}
  for row = 1, 60 do
    table.insert(base, string.format("line %02d", row))
  end

  local copy = function(lines)
    return vim.list_slice(lines, 1, #lines)
  end

  local test = function(spec)
    local before = spec.before and spec.before() or copy(base)
    local target = spec.target(copy(before))
    local expected = #target == 0 and { "" } or target
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, before)
    vim.api.nvim_win_set_cursor(0, { spec.row or 30, spec.col })

    local replacement = hunks.plan(util.buffer(buf), { text = table.concat(target, "\n"), endofline = true })
    local ok, err = pcall(hunks.apply, buf, replacement, function() end)
    assert(ok, spec.name .. ": " .. tostring(err))

    local actual = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local observed = {
      buffer = actual,
      cursor = cursor,
      line = vim.api.nvim_get_current_line(),
      marks = vim.api.nvim_buf_get_extmarks(buf, vim.api.nvim_create_namespace "fs-reconcile-cursor", 0, -1, {}),
    }
    assert(vim.deep_equal(actual, expected), vim.inspect { name = spec.name, observed = observed })
    assert(vim.deep_equal(cursor, spec.cursor), vim.inspect { name = spec.name, observed = observed })
    assert(observed.line == spec.line, vim.inspect { name = spec.name, observed = observed })
    assert(#observed.marks == 0, vim.inspect { name = spec.name, observed = observed })
  end

  local cases = {
    {
      name = "unchanged",
      col = 3,
      cursor = { 30, 3 },
      line = base[30],
      target = function(lines)
        return lines
      end,
    },
    {
      name = "insert above",
      col = 3,
      cursor = { 32, 3 },
      line = base[30],
      target = function(lines)
        table.insert(lines, 1, "above one")
        table.insert(lines, 2, "above two")
        return lines
      end,
    },
    {
      name = "delete above",
      col = 3,
      cursor = { 28, 3 },
      line = base[30],
      target = function(lines)
        table.remove(lines, 1)
        table.remove(lines, 1)
        return lines
      end,
    },
    {
      name = "insert below",
      col = 3,
      cursor = { 30, 3 },
      line = base[30],
      target = function(lines)
        table.insert(lines, 41, "below")
        return lines
      end,
    },
    {
      name = "delete below",
      col = 3,
      cursor = { 30, 3 },
      line = base[30],
      target = function(lines)
        table.remove(lines, 41)
        table.remove(lines, 41)
        return lines
      end,
    },
    {
      name = "insert at cursor column zero",
      col = 0,
      cursor = { 31, 0 },
      line = base[30],
      target = function(lines)
        table.insert(lines, 30, "before cursor")
        return lines
      end,
    },
    {
      name = "insert at cursor",
      col = 3,
      cursor = { 31, 3 },
      line = base[30],
      target = function(lines)
        table.insert(lines, 30, "before cursor")
        return lines
      end,
    },
    {
      name = "replace cursor column zero",
      col = 0,
      cursor = { 30, 0 },
      line = "replacement",
      target = function(lines)
        lines[30] = "replacement"
        return lines
      end,
    },
    {
      name = "shorten cursor line",
      col = 6,
      cursor = { 30, 0 },
      line = "x",
      target = function(lines)
        lines[30] = "x"
        return lines
      end,
    },
    {
      name = "lengthen cursor line",
      col = 3,
      cursor = { 30, 3 },
      line = "replacement is longer",
      target = function(lines)
        lines[30] = "replacement is longer"
        return lines
      end,
    },
    {
      name = "delete cursor line",
      col = 3,
      cursor = { 30, 3 },
      line = base[31],
      target = function(lines)
        table.remove(lines, 30)
        return lines
      end,
    },
    {
      name = "replace block containing cursor",
      col = 3,
      cursor = { 29, 3 },
      line = "block one",
      target = function(lines)
        lines[29] = "block one"
        lines[30] = "block two"
        table.remove(lines, 31)
        return lines
      end,
    },
    {
      name = "same-size block first row",
      row = 29,
      col = 3,
      cursor = { 29, 3 },
      line = "block one",
      target = function(lines)
        lines[29], lines[30], lines[31] = "block one", "block two", "block three"
        return lines
      end,
    },
    {
      name = "same-size block middle row",
      col = 3,
      cursor = { 30, 3 },
      line = "block two",
      target = function(lines)
        lines[29], lines[30], lines[31] = "block one", "block two", "block three"
        return lines
      end,
    },
    {
      name = "same-size block last row",
      row = 31,
      col = 3,
      cursor = { 31, 3 },
      line = "block three",
      target = function(lines)
        lines[29], lines[30], lines[31] = "block one", "block two", "block three"
        return lines
      end,
    },
    {
      name = "multiple hunks around cursor",
      col = 3,
      cursor = { 32, 3 },
      line = "replacement",
      target = function(lines)
        lines[30] = "replacement"
        table.insert(lines, 1, "above one")
        table.insert(lines, 2, "above two")
        table.insert(lines, 50, "below")
        return lines
      end,
    },
    {
      name = "empty replacement",
      col = 3,
      cursor = { 1, 0 },
      line = "",
      target = function()
        return {}
      end,
    },
    {
      name = "insert before first row",
      row = 1,
      col = 0,
      cursor = { 2, 0 },
      line = base[1],
      target = function(lines)
        table.insert(lines, 1, "before first")
        return lines
      end,
    },
    {
      name = "replace first row",
      row = 1,
      col = 0,
      cursor = { 1, 0 },
      line = "replacement",
      target = function(lines)
        lines[1] = "replacement"
        return lines
      end,
    },
    {
      name = "delete first row",
      row = 1,
      col = 3,
      cursor = { 1, 3 },
      line = base[2],
      target = function(lines)
        table.remove(lines, 1)
        return lines
      end,
    },
    {
      name = "delete last row",
      row = 60,
      col = 3,
      cursor = { 59, 3 },
      line = base[59],
      target = function(lines)
        table.remove(lines)
        return lines
      end,
    },
    {
      name = "insert before empty cursor line",
      row = 2,
      col = 0,
      cursor = { 3, 0 },
      line = "",
      before = function()
        return { "before", "", "after" }
      end,
      target = function(lines)
        table.insert(lines, 2, "inserted")
        return lines
      end,
    },
    {
      name = "replace empty cursor line",
      row = 2,
      col = 0,
      cursor = { 2, 0 },
      line = "replacement",
      before = function()
        return { "before", "", "after" }
      end,
      target = function(lines)
        lines[2] = "replacement"
        return lines
      end,
    },
    {
      name = "replace utf8 cursor line",
      col = 2,
      cursor = { 30, 2 },
      line = "αβγδ",
      before = function()
        local lines = copy(base)
        lines[30] = "αβγ"
        return lines
      end,
      target = function(lines)
        lines[30] = "αβγδ"
        return lines
      end,
    },
    {
      name = "shorten utf8 cursor line",
      col = 4,
      cursor = { 30, 0 },
      line = "α",
      before = function()
        local lines = copy(base)
        lines[30] = "αβγ"
        return lines
      end,
      target = function(lines)
        lines[30] = "α"
        return lines
      end,
    },
    {
      name = "populate empty buffer",
      row = 1,
      col = 0,
      cursor = { 1, 0 },
      line = "new",
      before = function()
        return { "" }
      end,
      target = function()
        return { "new" }
      end,
    },
    {
      name = "append after empty buffer line",
      row = 1,
      col = 0,
      cursor = { 1, 0 },
      line = "",
      before = function()
        return { "" }
      end,
      target = function()
        return { "", "new" }
      end,
    },
  }

  for _, spec in pairs(cases) do
    test(spec)
  end
end)
