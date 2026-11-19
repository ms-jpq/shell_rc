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

for _, case in ipairs {
  { "characters", "gg0vll", "1:1-1:4", 1, 1 },
  { "reversed characters", "gg03lvhh", "1:2-1:5", 1, 1 },
  { "lines", "ggVj", "1:1-2:9", 1, 2 },
  { "block", "gg0<C-v>jl", "1:1-2:3", 1, 2 },
} do
  T.test({ "REPL exits Visual mode before reading " .. case[1] .. " bounds", isolate = true }, function()
    require "go.to"
    vim.cmd.edit(T.file { "dogs run", "dogs nap", "dogs eat" })
    vim.b.__repl_target__ = "dogs" .. string.char(31) .. "target"
    local captured
    T.patch(require "goto.async", "system", function(_, options)
      T.eq("n", vim.fn.mode())
      captured = options.env
      return { code = 0, stdout = "", stderr = "" }
    end)
    T.patch(vim, "notify", function() end)
    local getregionpos = vim.fn.getregionpos
    T.patch(vim.fn, "getregionpos", function(...)
      T.eq("n", vim.fn.mode())
      return getregionpos(...)
    end)
    vim.cmd.normal { args = { vim.keycode(case[2]) }, bang = true }
    vim.api.nvim_feedkeys(vim.keycode [[\w]], "xt", false)
    assert(captured)
    T.eq(case[3], captured.REPL_LOCATION)
    T.eq(tostring(case[4]), captured.REPL_SELECT_LO)
    T.eq(tostring(case[5]), captured.REPL_SELECT_HI)
  end)
end

T.test({ "REPL records paths for new files and updates them after a rename" }, function()
  local root, _, repl = paths()
  vim.cmd.edit "relative/new-file"
  T.eq(vim.fs.joinpath(root, "relative", "new-file"), repl.buf_path(0))
  vim.cmd.file "renamed"
  T.eq(vim.api.nvim_buf_get_name(0), repl.buf_path(0))
end)
