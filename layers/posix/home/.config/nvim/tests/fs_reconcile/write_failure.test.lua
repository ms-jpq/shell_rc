local T = require "tests.lib"

T.test({ "write failure", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local writes = 0
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
    end,
  })

  local command = vim.cmd
  local fail = true
  T.patch(vim, "cmd", function(source)
    if fail and string.find(source, "noautocmd silent write!", 1, true) then
      fail = false
      error "synthetic write failure"
    end
    return command(source)
  end)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })

  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "local" }) and not vim.bo.modified and writes == 2
  end, {
    message = function()
      return vim.inspect { writes = writes, modified = vim.bo.modified, disk = vim.fn.readfile(path) }
    end,
  })
  vim.cmd = command
end)
