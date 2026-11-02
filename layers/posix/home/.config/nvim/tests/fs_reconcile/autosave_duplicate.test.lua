local T = require "tests.lib"

T.test({ "autosave duplicate", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local base = "vim.bo.commentstring = [[// %s]]"
  local appended = "-- this doesnt seem to be applied?"
  local expected = { base, appended }

  vim.fn.writefile({ base }, path)
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    once = true,
    callback = function()
      vim.fn.writefile(expected, path)
    end,
  })

  vim.api.nvim_buf_set_lines(0, 1, 1, true, { appended })

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected)
      and vim.deep_equal(vim.fn.readfile(path), expected)
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })
end)
