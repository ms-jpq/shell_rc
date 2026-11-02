local T = require "tests.lib"

T.test({ "formatter trailing space", timeout = 10000 }, function()
  local path = T.file { "a b c " }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  T.patch(vim.api, "nvim_get_mode", function()
    return { mode = "i" }
  end)
  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "a b c d" })
  local temporary = path .. ".formatter"
  vim.fn.writefile({ "a b c" }, temporary)
  assert(vim.uv.fs_rename(temporary, path))

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "a b c d" })
      and vim.deep_equal(vim.fn.readfile(path), { "a b c d" })
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
end)
