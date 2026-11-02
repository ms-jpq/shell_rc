local T = require "tests.lib"

local paths = function()
  local root = T.tempdir()
  local previous = vim.fn.getcwd()
  T.cleanup(function()
    vim.cmd.cd(previous)
  end)
  local target = vim.fs.joinpath(root, "target")
  assert(vim.fn.mkdir(target, "p") == 1)
  assert(vim.fn.writefile({ "dog" }, vim.fs.joinpath(target, "file")) == 0)
  assert(vim.uv.fs_symlink("target", vim.fs.joinpath(root, "relative"), { junction = false }))
  assert(vim.uv.fs_symlink(target, vim.fs.joinpath(root, "absolute"), { junction = false }))
  vim.cmd.cd(root)
  return vim.fn.getcwd(), target, require "goto.repl"
end

T.test({ "REPL retains the entered symlink path across cwd changes and alternate aliases" }, function()
  local root, target, repl = paths()
  vim.cmd.edit "relative/file"
  local relative = vim.fs.joinpath(root, "relative", "file")
  T.eq(relative, repl.buf_path(0))
  assert(vim.api.nvim_buf_get_name(0) ~= relative)
  vim.cmd.cd(target)
  T.eq(relative, repl.buf_path(0))
  vim.cmd.edit(vim.fs.joinpath(root, "absolute", "file"))
  T.eq(relative, repl.buf_path(0))
  vim.cmd.bwipeout()
  local absolute = vim.fs.joinpath(root, "absolute", "file")
  vim.cmd.edit(absolute)
  T.eq(absolute, repl.buf_path(0))
end)

T.test({ "REPL records paths for new files and updates them after a rename" }, function()
  local root, _, repl = paths()
  vim.cmd.edit "relative/new-file"
  T.eq(vim.fs.joinpath(root, "relative", "new-file"), repl.buf_path(0))
  vim.cmd.file "renamed"
  T.eq(vim.api.nvim_buf_get_name(0), repl.buf_path(0))
end)
