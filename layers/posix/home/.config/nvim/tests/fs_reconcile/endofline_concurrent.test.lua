local T = require "tests.lib"

T.test({ "endofline concurrent", timeout = 10000 }, function()
  local path = T.file { "a", "b" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  local hunks = require "goto.fs_reconcile.hunks"
  local apply = hunks.apply
  local before_save
  T.patch(hunks, "apply", function(...)
    apply(...)
    before_save = { disk = vim.fn.readblob(path), modified = vim.bo.modified }
  end)

  vim.bo.fixendofline = false
  vim.bo.endofline = false
  vim.fn.writefile({ "A", "b" }, path)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "A", "b" })
      and not vim.bo.endofline
      and vim.bo.fixendofline == false
      and not vim.bo.modified
      and vim.fn.readblob(path) == "A\nb"
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        endofline = vim.bo.endofline,
        fixendofline = vim.bo.fixendofline,
        modified = vim.bo.modified,
        disk = vim.fn.readblob(path),
      }
    end,
  })

  T.eq({ disk = "A\nb\n", modified = true }, before_save)
  assert(vim.fn.readblob(path) == "A\nb")
  assert(not vim.bo.modified)
end)
