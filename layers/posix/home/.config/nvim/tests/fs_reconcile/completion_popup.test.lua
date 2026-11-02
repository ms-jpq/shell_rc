local T = require "tests.lib"

T.test({ "reconciliation dismisses only the affected completion popup", timeout = 10000 }, function()
  local async = require "goto.async"
  local hunks = require "goto.fs_reconcile.hunks"

  vim.bo.swapfile = false
  vim.opt.completeopt = { "menuone", "noselect" }
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "do", "tail" })
  vim.api.nvim_win_set_cursor(0, { 1, 2 })

  vim.schedule(function()
    vim.cmd.startinsert { bang = true }
  end)
  async.sleep(30)
  assert(string.find(vim.api.nvim_get_mode().mode, "^i"))

  for _, selected in ipairs { false, true } do
    for _, row in ipairs { 0, 1 } do
      vim.api.nvim_buf_set_lines(0, 0, -1, true, { "do", "tail" })
      vim.api.nvim_win_set_cursor(0, { 1, 2 })
      vim.fn.complete(1, { "dog", "doodle" })
      if selected then
        vim.api.nvim_select_popupmenu_item(0, true, false, {})
        async.sleep(20)
        assert(vim.api.nvim_get_current_line() == "dog")
      end
      assert(vim.fn.pumvisible() == 1)
      hunks.apply(vim.api.nvim_get_current_buf(), {
        changes = { { start = row, finish = row + 1, records = { "remote\n" } } },
        endofline = true,
      }, function() end)
      local expected = row == 0 and { "remote", "tail" } or { selected and "dog" or "do", "remote" }
      assert(vim.fn.pumvisible() == 0, "completion popup remains open after reconciliation")
      assert(
        vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected),
        vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, true))
      )
      async.sleep(20)
      vim.api.nvim_input "<C-e>"
      async.sleep(20)
      assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected))
    end
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "do", "tail" })
  vim.api.nvim_win_set_cursor(0, { 1, 2 })
  vim.fn.complete(1, { "dog", "doodle" })
  local other = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(other, 0, -1, true, { "before" })
  hunks.apply(other, {
    changes = { { start = 0, finish = 1, records = { "after\n" } } },
    endofline = true,
  }, function() end)
  assert(vim.fn.pumvisible() == 1, "another buffer's completion was dismissed")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(other, 0, -1, true), { "after" }))
end)
