local T = require "tests.lib"

T.test({ "concurrent", timeout = 10000 }, function()
  local path = T.file { "a", "b", "c" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local hunks = require "goto.fs_reconcile.hunks"
  local apply = hunks.apply
  local before_save
  T.patch(hunks, "apply", function(...)
    apply(...)
    before_save = { disk = vim.fn.readfile(path), modified = vim.bo.modified }
  end)

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "A" })
  vim.fn.writefile({ "a", "B", "c" }, path)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "A", "B", "c" })
      and vim.deep_equal(vim.fn.readfile(path), { "A", "B", "c" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
      }
    end,
  })

  T.eq({ disk = { "a", "B", "c" }, modified = true }, before_save)
  assert(vim.deep_equal(vim.fn.readfile(path), { "A", "B", "c" }))
  assert(not vim.bo.modified)
end)
