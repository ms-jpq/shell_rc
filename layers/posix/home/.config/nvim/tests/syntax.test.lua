local T = require "tests.lib"

local syntax = function(language, lines)
  vim.cmd.enew { bang = true }
  vim.cmd.syntax "clear"
  vim.wo.conceallevel = 2
  vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
  vim.cmd.source(vim.fs.joinpath(T.root, "pack/local/start/goto/syntax", "cole_" .. language .. ".vim"))
end

local concealed = function(checks)
  for _, check in ipairs(checks) do
    local actual = vim.fn.synconcealed(check.row, check.col)
    local group = vim.fn.synIDattr(vim.fn.synID(check.row, check.col, 1), "name")
    assert(actual[1] == 1 and actual[2] == check.char, vim.inspect { actual = actual, check = check, group = group })
  end
end

for _, case in ipairs {
  { "awk", "#" },
  { "bash", "#" },
  { "c", "//" },
  { "cpp", "//" },
  { "dart", "//" },
  { "elixir", "#" },
  { "fsharp", "//" },
  { "go", "//" },
  { "haskell", "--" },
  { "java", "//" },
  { "javascript", "//" },
  { "javascriptreact", "//" },
  { "kotlin", "//" },
  { "lua", "--" },
  { "nim", "#" },
  { "perl", "#" },
  { "python", "#" },
  { "r", "#" },
  { "ruby", "#" },
  { "rust", "//" },
  { "scala", "//" },
  { "sh", "#" },
  { "swift", "//" },
  { "typescript", "//" },
  { "typescriptreact", "//" },
  { "vim", '"' },
  { "zsh", "#" },
} do
  local language, opener = unpack(case)
  T.test({ language .. " distinguishes ordinary comments from REPL responses" }, function()
    syntax(language, { opener .. " ordinary", opener .. " |", opener .. " | response", opener .. " |response" })
    concealed {
      { row = 1, col = 1, char = "│" },
      { row = 2, col = 1, char = "┇" },
      { row = 3, col = 1, char = "┇" },
      { row = 4, col = 1, char = "┇" },
    }
  end)
end

T.test({ "PHP recognizes both comment styles in REPL responses" }, function()
  syntax(
    "php",
    { "# ordinary", "# |", "# | response", "# |response", "// ordinary", "// |", "// | response", "// |response" }
  )
  concealed {
    { row = 1, col = 1, char = "│" },
    { row = 2, col = 1, char = "┇" },
    { row = 3, col = 1, char = "┇" },
    { row = 4, col = 1, char = "┇" },
    { row = 5, col = 1, char = "│" },
    { row = 6, col = 1, char = "┇" },
    { row = 7, col = 1, char = "┇" },
    { row = 8, col = 1, char = "┇" },
  }
end)

T.test({ "Markdown REPL comments conceal their closing delimiters" }, function()
  syntax("markdown", { "<!-- ordinary -->", "<!-- |", "<!-- | response -->", "<!-- |response -->" })
  concealed {
    { row = 1, col = 1, char = "│" },
    { row = 2, col = 1, char = "┇" },
    { row = 3, col = 1, char = "┇" },
    { row = 3, col = 17, char = "" },
    { row = 4, col = 1, char = "┇" },
    { row = 4, col = 16, char = "" },
  }
end)

T.test({ "Markdown recognizes machine quotes with or without spaces and inside nested quotes" }, function()
  syntax("markdown", { "> | spaced", "> |plain", "> > | nested" })
  for _, position in ipairs { { 1, 3 }, { 2, 3 }, { 3, 5 } } do
    T.eq("mdMachineQuote", vim.fn.synIDattr(vim.fn.synID(position[1], position[2], 1), "name"))
  end
end)

for _, language in ipairs { "javascript", "typescript", "javascriptreact", "typescriptreact" } do
  T.test({ language .. " conceals JSDoc boundaries without changing comment-like strings" }, function()
    syntax(language, {
      "    /**",
      "     * Gets or sets a value.",
      "     *",
      "     */",
      "    /* ordinary */",
      'const text = "/**";',
      "    /** docs */",
      "    /** */",
      "    /**/",
      '    /** docs */ const text = "*/";',
      "    /** Starts here",
      "     */",
    })
    for _, check in ipairs {
      { 1, 5, "┌" },
      { 1, 7, "┐" },
      { 2, 6, "│" },
      { 3, 6, "│" },
      { 4, 6, "└" },
      { 5, 5, "┌" },
      { 5, 7, "" },
      { 6, 17, "" },
      { 5, 17, "┘" },
      { 7, 7, "─" },
      { 7, 14, "┘" },
      { 8, 7, "─" },
      { 8, 9, "┘" },
      { 9, 5, "┌" },
      { 9, 7, "┘" },
      { 10, 31, "" },
      { 11, 7, "┐" },
      { 12, 6, "└" },
    } do
      local row, column, expected = check[1], check[2], check[3]
      T.eq(expected, vim.fn.synconcealed(row, column)[2])
    end
  end)
end

T.test({ "Lua block keywords conceal only complete words" }, function()
  syntax("lua", { "end", "  end", "ending", "do", "  do", "if ok then" })
  for _, check in ipairs {
    { 1, 1, "⌋" },
    { 2, 3, "⌋" },
    { 3, 1, "" },
    { 4, 1, "⌈" },
    { 5, 3, "⌈" },
    { 6, 7, "⌈" },
  } do
    T.eq(check[3], vim.fn.synconcealed(check[1], check[2])[2])
  end
end)

T.test({ "Lua conceals standalone require calls but preserves chained calls" }, function()
  local lines = {
    'require "dogs"',
    "require [[dogs]]",
    'require("dogs")',
    "require([[dogs]])",
    'local dogs = require "dogs"',
    'require "dogs" -- a comment',
    'require "dogs".setup()',
    "require [[dogs]].setup()",
    'require("dogs").setup()',
    "require([[dogs]]).setup()",
  }
  syntax("lua", lines)
  for row, line in ipairs(lines) do
    local column = assert(string.find(line, "require", 1, true))
    local actual = vim.fn.synconcealed(row, column)
    T.eq(row <= 6 and 1 or 0, actual[1])
    if row <= 6 then
      T.eq("←", actual[2])
    end
  end
end)

T.test({ "shell block separators conceal without hiding ordinary semicolons" }, function()
  syntax("sh", { "if condition; then", "if condition ;    then", "while condition; do", "first; second" })
  for _, check in ipairs {
    { 1, 13, 1, "" },
    { 1, 15, 1, "⌈" },
    { 2, 14, 1, "" },
    { 2, 19, 1, "⌈" },
    { 3, 16, 1, "" },
    { 3, 18, 1, "⌈" },
    { 4, 6, 0, "" },
  } do
    local actual = vim.fn.synconcealed(check[1], check[2])
    T.eq(check[3], actual[1])
    T.eq(check[4], actual[2])
  end
end)
