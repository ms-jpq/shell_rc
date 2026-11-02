local T = require "tests.lib"

T.test({ "own typing", timeout = 10000 }, function()
  local async = require "goto.async"
  local hunks = require "goto.fs_reconcile.hunks"
  local filename = T.file { "" }
  vim.cmd.edit(filename)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  async.sleep(100)

  local merges = {}
  local merge = hunks.merge
  T.patch(hunks, "merge", function(base, current, disk)
    table.insert(merges, { base = base.text, current = current.text, disk = disk.text })
    return merge(base, current, disk)
  end)

  for index, delay in ipairs { 0, 20, 100, 280, 310, 400, 650 } do
    local prefix = tostring(index) .. ": we have all the "
    vim.api.nvim_buf_set_lines(0, 0, -1, true, { prefix .. "skilsl right?" })
    async.sleep(delay)
    local expected = { prefix .. "skills right?" }
    vim.api.nvim_buf_set_lines(0, 0, -1, true, expected)
    async.sleep(650)
    assert(
      vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected),
      vim.inspect {
        delay = delay,
        merges = merges,
        actual = vim.api.nvim_buf_get_lines(0, 0, -1, true),
      }
    )
    assert(vim.deep_equal(vim.fn.readfile(filename), expected))
    assert(not vim.bo.modified)
  end
  hunks.merge = merge
  assert(#merges == 0, vim.inspect(merges))
end)
