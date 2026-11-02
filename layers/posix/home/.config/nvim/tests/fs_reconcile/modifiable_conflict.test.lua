local T = require "tests.lib"

T.test({ "modifiable conflict", timeout = 10000 }, function()
  local path = T.file { "a", "b", "c" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local hunks = require "goto.fs_reconcile.hunks"
  local apply = hunks.apply
  local before_save
  T.patch(hunks, "apply", function(...)
    apply(...)
    before_save = { disk = vim.fn.readfile(path), modified = vim.bo.modified }
  end)

  local writes = 0
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "A" })
  vim.bo.modifiable = false
  vim.fn.writefile({ "a", "B", "c" }, path)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "A", "b", "c" })
      and vim.deep_equal(vim.fn.readfile(path), { "a", "B", "c" })
      and writes == 0
  end, {
    timeout = 1000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        writes = writes,
      }
    end,
  })

  vim.bo.modifiable = true
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "A", "B", "c" })
      and vim.deep_equal(vim.fn.readfile(path), { "A", "B", "c" })
      and not vim.bo.modified
      and writes == 1
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        writes = writes,
      }
    end,
  })

  T.eq({ disk = { "a", "B", "c" }, modified = true }, before_save)
  assert(vim.deep_equal(vim.fn.readfile(path), { "A", "B", "c" }))
  assert(not vim.bo.modified)
  assert(writes == 1)
end)
