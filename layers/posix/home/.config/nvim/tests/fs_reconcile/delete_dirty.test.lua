local T = require "tests.lib"

T.test({ "delete dirty", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  local writes = 0
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  assert(vim.uv.fs_unlink(path))
  require("goto.async").sleep(1200)

  assert(not vim.uv.fs_stat(path))
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local" }))
  assert(vim.bo.modified)
  assert(writes == 0, vim.inspect { writes = writes })

  vim.cmd.write()
  assert(vim.deep_equal(vim.fn.readfile(path), { "local" }))
  assert(not vim.bo.modified)
end)
