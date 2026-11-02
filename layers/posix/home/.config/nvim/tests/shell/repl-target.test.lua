local T = require "tests.lib"

for _, case in ipairs {
  { "frontmatter restricts target discovery to the declared path", "/locked", "", { "@locked" } },
  { "explicit all-target mode overrides a declared path", "/locked", "*", { "@locked", "@outside" } },
  { "frontmatter wildcard includes all other panes", "*", "", { "@locked", "@outside" } },
} do
  T.test({ case[1], isolate = false }, function()
    local directory = T.tempdir()
    local bin = vim.fs.joinpath(directory, "bin")
    assert(vim.fn.mkdir(bin, "p") == 1)
    local mock = vim.fs.joinpath(bin, "tmux")
    assert(vim.uv.fs_copyfile(vim.fs.joinpath(T.root, "tests/fixtures/repl-tmux.sh"), mock))
    assert(vim.uv.fs_chmod(mock, 493))
    local file = vim.fs.joinpath(directory, "dogs.md")
    assert(vim.fn.writefile({ "---", "repl-target: " .. case[2], "---" }, file) == 0)
    local separator = string.char(31)
    local result = T.process({ vim.fs.joinpath(T.root, "pack/local/start/goto/libexec/repl.sh") }, {
      env = {
        PATH = bin .. ":" .. vim.env.PATH,
        TMUX = "/tmp/dog.sock,123,0",
        TMUX_PANE = "@caller",
        __TMUX_ROOT_SOCKET__ = "",
        __TMUX_ROOT_PANE__ = "",
        REPL_ANCESTOR_PATHS = "/project:/",
        REPL_FILE_NAME = file,
        REPL_IFS = separator,
        REPL_LOCATION = "1:1",
        REPL_LINE_COUNT = "3",
        REPL_SELECT_LO = "1",
        REPL_SELECT_HI = "1",
        REPL_PARENT_PATH = "/project/src",
        REPL_PRETTY_NAME = "dogs.md",
        REPL_TARGET = case[3],
      },
    })
    assert(result.code == 0 and result.signal == 0, result.stderr)
    local panes = vim
      .iter(vim.split(result.stdout, "\0", { plain = true, trimempty = true }))
      :map(function(record)
        local pane = unpack(vim.split(record, separator, { plain = true }))
        return pane
      end)
      :totable()
    T.eq(case[4], panes)
  end)
end
