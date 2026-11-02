local T = require "tests.lib"

T.test({ "hunk views", timeout = 10000 }, function()
  local apply = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"

  local before = {}
  for row = 1, 60 do
    before[row] = string.format("L%03d %s", row, string.rep("x", 120))
  end
  local after = vim.list_slice(before, 1, #before)
  after[12] = "L012 agent"
  after[43] = "L043 agent"

  vim.cmd.vsplit()
  local windows = vim.api.nvim_list_wins()
  local specs = {
    { lnum = 12, col = 90, curswant = 90, topline = 8, leftcol = 24 },
    { lnum = 43, col = 90, curswant = 90, topline = 36, leftcol = 24 },
  }

  local setup = function(buf)
    for index, win in ipairs(windows) do
      vim.api.nvim_win_set_buf(win, buf)
      vim.api.nvim_win_call(win, function()
        vim.wo.wrap = false
        vim.fn.winrestview(specs[index])
      end)
    end
  end

  local views = function()
    return vim
      .iter(windows)
      :map(function(win)
        return vim.api.nvim_win_call(win, vim.fn.winsaveview)
      end)
      :totable()
  end

  local actual = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(actual, 0, -1, true, before)
  setup(actual)

  local current = util.buffer(actual)
  local replacement = apply.plan(current, { text = table.concat(after, "\n"), endofline = true })
  local before_views = views()
  apply.apply(actual, replacement, function() end)
  local observed = views()

  for index, view in ipairs(observed) do
    assert(view.lnum == specs[index].lnum, vim.inspect { index = index, view = view })
    assert(view.col == #after[specs[index].lnum] - 1, vim.inspect { index = index, view = view })
    assert(view.topline == before_views[index].topline, vim.inspect { index = index, view = view })
  end

  local tracked = function(target, offset)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, before)
    setup(buf)

    local change = apply.plan(util.buffer(buf), { text = table.concat(target, "\n"), endofline = true })
    apply.apply(buf, change, function() end)
    for index, view in ipairs(views()) do
      local spec = specs[index]
      assert(view.lnum == spec.lnum + offset, vim.inspect { offset = offset, observed = views() })
      assert(view.topline == spec.topline + offset, vim.inspect { offset = offset, observed = views() })
      assert(vim.api.nvim_buf_get_lines(buf, view.lnum - 1, view.lnum, true)[1] == before[spec.lnum])
    end
  end

  local inserted = vim.list_slice(before, 1, #before)
  table.insert(inserted, 1, "agent one")
  table.insert(inserted, 2, "agent two")
  tracked(inserted, 2)

  tracked(vim.list_slice(before, 3, #before), -2)

  local same_size = vim.list_slice(before, 1, #before)
  same_size[12], same_size[13], same_size[14] = "agent 12", "agent 13", "agent 14"
  local same_size_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(same_size_buf, 0, -1, true, before)
  for index, win in ipairs(windows) do
    vim.api.nvim_win_set_buf(win, same_size_buf)
    vim.api.nvim_win_set_cursor(win, { index + 11, 0 })
  end
  local same_size_change = apply.plan(util.buffer(same_size_buf), {
    text = table.concat(same_size, "\n"),
    endofline = true,
  })
  apply.apply(same_size_buf, same_size_change, function() end)
  for index, win in ipairs(windows) do
    local row = unpack(vim.api.nvim_win_get_cursor(win))
    assert(row == index + 11)
    assert(vim.api.nvim_buf_get_lines(same_size_buf, row - 1, row, true)[1] == same_size[row])
  end
end)
