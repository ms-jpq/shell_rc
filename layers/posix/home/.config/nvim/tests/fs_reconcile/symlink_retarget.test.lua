local T = require "tests.lib"

T.test({ "symlink retarget", timeout = 10000 }, function()
  local root = vim.fn.tempname()
  local first = vim.fs.joinpath(root, "first")
  local second = vim.fs.joinpath(root, "second")
  local link = vim.fs.joinpath(root, "link")
  assert(vim.uv.fs_mkdir(root, 493))
  vim.fn.writefile({ "a", "b" }, first)
  vim.fn.writefile({ "a", "agent" }, second)
  assert(vim.uv.fs_symlink(first, link, { junction = false }))

  vim.cmd.edit(link)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "local" })
  assert(vim.uv.fs_unlink(link))
  assert(vim.uv.fs_symlink(second, link, { junction = false }))

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local", "agent" })
      and vim.deep_equal(vim.fn.readfile(first), { "a", "b" })
      and vim.deep_equal(vim.fn.readfile(second), { "local", "agent" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        first = vim.fn.readfile(first),
        second = vim.fn.readfile(second),
        modified = vim.bo.modified,
      }
    end,
  })

  assert(vim.deep_equal(vim.fn.readfile(second), { "local", "agent" }))
  assert(vim.deep_equal(vim.fn.readfile(first), { "a", "b" }))
  assert(not vim.bo.modified)
end)
