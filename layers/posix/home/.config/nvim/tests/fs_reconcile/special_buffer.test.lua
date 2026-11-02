local T = require "tests.lib"

T.test({ "special buffer", timeout = 10000 }, function()
  require "goto.fs_reconcile"
  local buf = vim.api.nvim_create_buf(true, false)
  vim.bo[buf].buftype = "nofile"
  vim.api.nvim_buf_set_name(buf, vim.fn.tempname())
  vim.api.nvim_exec_autocmds({ "BufReadPost" }, { buffer = buf })

  assert(vim.b[buf].__fs_reconcile__ == nil)
end)
