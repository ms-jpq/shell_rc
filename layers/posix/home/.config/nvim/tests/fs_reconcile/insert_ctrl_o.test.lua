local T = require "tests.lib"

T.test({ "insert ctrl o", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local mode_changed = function(old_mode, new_mode)
    vim.api.nvim_exec_autocmds("ModeChanged", {
      data = { old_mode = old_mode, new_mode = new_mode },
    })
  end

  mode_changed("n", "i")
  mode_changed("i", "niI")
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })

  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "local" }) and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path), modified = vim.bo.modified }
    end,
  })
end)
