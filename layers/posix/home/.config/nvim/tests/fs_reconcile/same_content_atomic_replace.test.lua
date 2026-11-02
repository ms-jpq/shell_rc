local T = require "tests.lib"

T.test({ "same content atomic replace", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local content = { "same" }
  vim.fn.writefile(content, path)
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

  local temporary = path .. ".agent"
  vim.fn.writefile(content, temporary)
  assert(vim.uv.fs_rename(temporary, path))

  require("goto.async").sleep(1000)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), content))
  assert(not vim.bo.modified)
  assert(writes == 0, vim.inspect { writes = writes })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "local" }) and not vim.bo.modified and writes == 1
  end, {
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path), writes = writes }
    end,
  })
end)
