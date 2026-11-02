local T = require "tests.lib"

T.test({ "own saveas", timeout = 10000 }, function()
  local async = require "goto.async"
  local initial, destination = vim.fn.tempname(), vim.fn.tempname()
  local prefix = "so i think there is something really imporatnt, which is we"
  local typo = prefix .. " have all the skilsl right?"
  local corrected = prefix .. " have all the skills right?"

  vim.fn.writefile({ prefix }, initial)
  vim.cmd.edit(initial)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  async.sleep(100)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { typo })
  vim.cmd.saveas(destination)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { corrected })
  async.sleep(2000)

  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local disk = vim.fn.readfile(destination)
  assert(
    vim.deep_equal(actual, { corrected }) and vim.deep_equal(disk, { corrected }),
    vim.inspect {
      expected = { corrected },
      actual = actual,
      disk = disk,
    }
  )
end)
