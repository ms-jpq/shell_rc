local T = require "tests.lib"

T.test({ "single line replacements preserve native cursor and scroll state", timeout = 20000 }, function()
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"
  local texts = { "", "犬 dog", "a 🐕 b", "éclair", string.rep("a", 200) }
  local prefixes = { "" }
  for _ = 1, 3 do
    local next_prefixes = {}
    for _, prefix in ipairs(prefixes) do
      for _, character in ipairs { "a", "b", " " } do
        table.insert(next_prefixes, prefix .. character)
      end
    end
    vim.list_extend(texts, next_prefixes)
    prefixes = next_prefixes
  end
  local direct = vim.api.nvim_create_buf(true, false)
  local actual = vim.api.nvim_create_buf(true, false)
  vim.wo.wrap = false
  local setup = function(buf, text, col)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { text })
    vim.fn.winrestview { lnum = 1, col = col, curswant = col, topline = 1, leftcol = math.max(0, col - 30) }
  end
  for _, before in ipairs(texts) do
    for _, after in ipairs(texts) do
      if before ~= after then
        for _, col in ipairs { 0, math.max(0, #before - 1) } do
          setup(direct, before, col)
          vim.api.nvim_buf_set_lines(direct, 0, -1, true, { after })
          local expected = vim.fn.winsaveview()
          setup(actual, before, col)
          hunks.apply(actual, hunks.plan(util.buffer(actual), { text = after, endofline = true }), function() end)
          local observed = vim.fn.winsaveview()
          for _, key in ipairs { "lnum", "col", "curswant", "topline", "leftcol", "skipcol", "coladd" } do
            assert(
              expected[key] == observed[key],
              vim.inspect {
                before = before,
                after = after,
                col = col,
                key = key,
                expected = expected,
                observed = observed,
              }
            )
          end
        end
      end
    end
  end
end)

T.test({ "small multiline replacements retain valid cursor anchors", timeout = 20000 }, function()
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"
  local texts, level = {}, { {} }
  for _ = 1, 3 do
    local next_level = {}
    for _, prefix in ipairs(level) do
      for _, line in ipairs { "", "a", "b" } do
        local lines = vim.list_slice(prefix)
        table.insert(lines, line)
        table.insert(next_level, lines)
      end
    end
    vim.list_extend(texts, next_level)
    level = next_level
  end
  local buf = vim.api.nvim_get_current_buf()
  for _, before in ipairs(texts) do
    for _, after in ipairs(texts) do
      for row in ipairs(before) do
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, before)
        vim.api.nvim_win_set_cursor(0, { row, 0 })
        hunks.apply(
          buf,
          hunks.plan(util.buffer(buf), { text = table.concat(after, "\n"), endofline = true }),
          function() end
        )
        T.eq(after, vim.api.nvim_buf_get_lines(buf, 0, -1, true))
        local cursor = vim.api.nvim_win_get_cursor(0)
        assert(cursor[1] >= 1 and cursor[1] <= #after)
        T.eq(0, cursor[2])
        if vim.deep_equal(before, after) then
          T.eq({ row, 0 }, cursor)
        end
      end
    end
  end
end)
