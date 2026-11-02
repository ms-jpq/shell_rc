local T = require "tests.lib"

T.test({ "symlink clean retarget", timeout = 10000 }, function()
  local root = vim.fn.tempname()
  local first = vim.fs.joinpath(root, "first")
  local second = vim.fs.joinpath(root, "second")
  local link = vim.fs.joinpath(root, "link")
  assert(vim.uv.fs_mkdir(root, 493))
  vim.fn.writefile({ "base" }, first)
  vim.fn.writefile({ "agent" }, second)
  assert(vim.uv.fs_symlink(first, link, { junction = false }))

  vim.cmd.edit(link)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  assert(vim.uv.fs_unlink(link))
  assert(vim.uv.fs_symlink(second, link, { junction = false }))
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.modified
  end)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(second), { "local" }) and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect { disk = vim.fn.readfile(second), modified = vim.bo.modified }
    end,
  })
end)
