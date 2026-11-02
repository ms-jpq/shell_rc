local T = require "tests.lib"

T.test({ "insert mode", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.schedule(function()
    vim.cmd.startinsert()
  end)
  T.eventually(function()
    return string.find(vim.api.nvim_get_mode().mode, "^i") ~= nil
  end)
  vim.api.nvim_input "L"
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "Lbase" })
      and vim.deep_equal(vim.fn.readfile(path), { "Lbase" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path), lines = vim.api.nvim_buf_get_lines(0, 0, -1, true) }
    end,
  })
  assert(string.find(vim.api.nvim_get_mode().mode, "^i"))
  vim.api.nvim_input "<Esc>"
end)
