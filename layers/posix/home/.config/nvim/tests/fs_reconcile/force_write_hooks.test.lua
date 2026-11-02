local T = require "tests.lib"

T.test({ "force write hooks", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local post = 0
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    once = true,
    callback = function()
      vim.api.nvim_buf_set_lines(0, 0, -1, true, { "formatted" })
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = 0,
    callback = function()
      post = post + 1
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd [[write!]]

  assert(vim.deep_equal(vim.fn.readfile(path), { "formatted" }))
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "formatted" }))
  assert(post == 1, vim.inspect { post = post })
end)
