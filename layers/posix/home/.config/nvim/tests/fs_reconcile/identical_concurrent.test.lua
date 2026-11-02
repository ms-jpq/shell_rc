local T = require "tests.lib"

T.test({ "identical concurrent", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end, { timeout = 1000 })

  local hunks = require "goto.fs_reconcile.hunks"
  local merge = hunks.merge
  T.patch(hunks, "merge", function(...)
    error "identical buffers must not merge"
  end)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "adopted" })
  vim.fn.writefile({ "adopted" }, path)
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "adopted" })
      and vim.deep_equal(vim.fn.readfile(path), { "adopted" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })

  hunks.merge = merge
end)
