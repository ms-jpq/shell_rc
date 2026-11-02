local T = require "tests.lib"

T.test({ "local edits and normal-mode typing reach disk", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_clear_autocmds { group = "lv_goto", event = { "TextChanged", "TextChangedI", "TextChangedP" } }
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })

  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "local" })
  end, {
    message = function()
      return vim.inspect(vim.fn.readfile(path))
    end,
  })

  local keys = vim.api.nvim_replace_termcodes("onormal<Esc>", true, false, true)
  vim.api.nvim_feedkeys(keys, "xt", false)
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "local", "normal" }) and not vim.bo.modified
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
