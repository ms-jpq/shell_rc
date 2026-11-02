local T = require "tests.lib"

T.test({ "insert concurrent", timeout = 10000 }, function()
  local path = T.file { "a", "b", "c" }
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

  local async = require "goto.async"
  local entered = async.future()
  vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    buffer = 0,
    once = true,
    callback = entered.resolve,
  })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.schedule(function()
    vim.cmd.startinsert()
  end)
  entered.await()
  vim.api.nvim_input "A"
  async.sleep(30)
  assert(string.find(vim.api.nvim_get_mode().mode, "^i"))
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "Aa", "b", "c" }))
  local temporary = path .. ".agent"
  vim.fn.writefile({ "a", "B", "c" }, temporary)
  assert(vim.uv.fs_rename(temporary, path))

  local merged = { "Aa", "B", "c" }
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), merged)
      and vim.deep_equal(vim.fn.readfile(path), merged)
      and not vim.bo.modified
      and writes == 1
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        writes = writes,
      }
    end,
  })

  assert(string.find(vim.api.nvim_get_mode().mode, "^i"))
  assert(vim.deep_equal(vim.fn.readfile(path), merged))
  assert(not vim.bo.modified)
  assert(writes == 1)
  vim.api.nvim_input "<Esc>"
end)
