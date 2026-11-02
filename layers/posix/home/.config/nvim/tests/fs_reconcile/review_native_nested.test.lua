local T = require "tests.lib"

T.test({ "review native nested", timeout = 10000 }, function()
  local async = require "goto.async"
  local filename = vim.fn.tempname()
  local prefix = "so i think there is something really imporatnt, which is we"
  local typo = prefix .. " have all the skilsl right?"
  local corrected = prefix .. " have all the skills right?"
  vim.fn.writefile({ prefix }, filename)
  vim.cmd.edit(filename)
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = 0,
    once = true,
    callback = function()
      vim.api.nvim_buf_set_lines(0, 0, -1, true, { corrected })
    end,
  })
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  async.sleep(100)
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    once = true,
    callback = function()
      vim.wait(10, function()
        return false
      end)
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { typo })
  vim.cmd.write()
  async.sleep(2000)
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local disk = vim.fn.readfile(filename)
  assert(
    vim.deep_equal(actual, { corrected }) and vim.deep_equal(disk, { corrected }),
    vim.inspect { expected = corrected, actual = actual, disk = disk }
  )
end)
