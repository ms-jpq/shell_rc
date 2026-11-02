local T = require "tests.lib"

T.test({ "cursor remote", timeout = 10000 }, function()
  local disk = vim.fn.tempname()
  local before = {}
  for row = 1, 60 do
    table.insert(before, string.format("line %02d", row))
  end

  vim.fn.writefile(before, disk)
  vim.cmd.edit(disk)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local wait_for = function(lines)
    T.eventually(function()
      return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), lines)
    end, {
      message = function()
        return vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, true))
      end,
    })
  end

  vim.fn.winrestview { lnum = 30, col = 3, topline = 24 }
  local view = vim.fn.winsaveview()

  local after = vim.list_slice(before, 1, #before)
  table.insert(after, 1, "external one")
  table.insert(after, 2, "external two")
  vim.fn.writefile(after, disk)

  wait_for(after)

  local observed = vim.fn.winsaveview()
  assert(observed.lnum == view.lnum + 2, vim.inspect { expected = view, observed = observed })
  assert(observed.topline == view.topline + 2, vim.inspect { expected = view, observed = observed })
  assert(vim.api.nvim_get_current_line() == before[view.lnum])

  local final = vim.list_slice(after, 5, #after)
  vim.fn.writefile(final, disk)

  wait_for(final)

  observed = vim.fn.winsaveview()
  assert(observed.lnum == view.lnum - 2, vim.inspect { expected = view, observed = observed })
  assert(observed.topline == view.topline - 2, vim.inspect { expected = view, observed = observed })
  assert(vim.api.nvim_get_current_line() == before[view.lnum])

  local cursor_row = view.lnum - 2
  local replaced = vim.list_slice(final, 1, #final)
  replaced[cursor_row] = "x"
  vim.fn.writefile(replaced, disk)
  wait_for(replaced)

  observed = vim.fn.winsaveview()
  assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { cursor_row, 0 }), vim.inspect(observed))
  assert(vim.api.nvim_get_current_line() == "x")

  local inserted = vim.list_slice(replaced, 1, #replaced)
  table.insert(inserted, cursor_row, "before cursor")
  vim.fn.writefile(inserted, disk)
  wait_for(inserted)

  observed = vim.fn.winsaveview()
  assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { cursor_row + 1, 0 }), vim.inspect(observed))
  assert(vim.api.nvim_get_current_line() == "x")
end)
