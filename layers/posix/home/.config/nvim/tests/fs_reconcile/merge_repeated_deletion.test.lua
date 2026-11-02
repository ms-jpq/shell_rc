local T = require "tests.lib"

T.test({ "repeated-content conflicts preserve independent edits", timeout = 10000, isolate = false }, function()
  local module = require "goto.fs_reconcile.hunks.merge"
  local merge = module.merge
  local hunks = require "goto.fs_reconcile.hunks"

  local cases = {
    { "trailing blanks", "dogs\n\n\n", "dogs\n\n\n\n", "dogs\n", "dogs\n\n\n\n", "dogs\n" },
    { "leading blanks", "\n\ndogs", "\n\n\ndogs", "dogs", "\n\n\ndogs", "dogs" },
    { "internal blanks", "dogs\n\n\nend", "dogs\n\n\n\nend", "dogs\nend", "dogs\n\n\n\nend", "dogs\nend" },
    {
      "repeated lines",
      "dogs\nlil\nlil\nend",
      "dogs\nlil\nlil\nlil\nend",
      "dogs\nend",
      "dogs\nlil\nlil\nlil\nend",
      "dogs\nend",
    },
    {
      "unrelated deletion",
      "dogs\nwang\nlil\nend",
      "dogs\nwang\nlil\nlil\nend",
      "dogs\nend",
      "dogs\nlil\nlil\nend",
      "dogs\nend",
    },
    {
      "independent insertion",
      "dogs\nlil\nend",
      "dogs\nlil\nwang\nend",
      "dogs\nend",
      "dogs\nwang\nend",
      "dogs\nwang\nend",
    },
    {
      "partial run deletion",
      "dogs\nlil\nlil\nend",
      "dogs\nlil\nlil\nlil\nend",
      "dogs\nlil\nend",
      "dogs\nlil\nlil\nlil\nend",
      "dogs\nlil\nend",
    },
    {
      "repeated block",
      "dogs\nlil\nwang\nlil\nwang\nend",
      "dogs\nlil\nwang\nlil\nwang\nlil\nwang\nend",
      "dogs\nend",
      "dogs\nlil\nwang\nlil\nwang\nlil\nwang\nend",
      "dogs\nend",
    },
    {
      "unicode run",
      "dogs\n犬\n犬\nend",
      "dogs\n犬\n犬\n犬\nend",
      "dogs\nend",
      "dogs\n犬\n犬\n犬\nend",
      "dogs\nend",
    },
    { "character run", "dog!!", "dog!!!", "dog", "dog!!!", "dog" },
    { "concurrent character extensions", "dog", "dogg", "doggg", "doggg", "doggg" },
    {
      "an independent remote line split survives a repeated character conflict",
      "\nbba\n",
      "\nbbba\n",
      "b\na\nb\n",
      "\nbbb\na\nb\n",
      "b\na\nb\n",
    },
    {
      "a remote replacement survives a repeated deletion conflict",
      "abaaaaaa\na\n\na\n",
      "a\nb\n\n\na\na\n",
      "aba\naab",
      "a\nb\n\n\naba\n",
      "a\nba\nab",
    },
    {
      "local deletion wins despite another local insertion",
      "\nba\na\n\n\n\na",
      "\n\nba\n",
      "a\n\n\n\n\na",
      "\nba\n",
      "\n\nba\n\n",
    },
    {
      "independent remote inserted lines survive a repeated blank conflict",
      "\n\n\n\nbb",
      "\n\n\n\n\nbb",
      "\nb\na\na\n",
      "\nb\na\na\n\n\n\n",
      "\nb\na\na\n",
    },
    {
      "concurrent block extensions",
      "a\nb\nend",
      "a\nb\na\nend",
      "a\nb\na\nb\nend",
      "a\nb\na\nb\nend",
      "a\nb\na\nb\nend",
    },
  }

  local failures = {}
  for mode, fn in pairs {
    synchronous = merge,
    asynchronous = function(base, left, right)
      return hunks.merge(
        { text = base, endofline = true },
        { text = left, endofline = true },
        { text = right, endofline = true }
      ).text
    end,
  } do
    for _, case in ipairs(cases) do
      local name, base, left, right, expected, reversed = unpack(case)
      for _, pair in ipairs { { left, right, expected }, { right, left, reversed } } do
        local actual = fn(base, pair[1], pair[2])
        if actual ~= pair[3] then
          table.insert(failures, { mode = mode, name = name, pair = pair, actual = actual })
        end
        assert(fn(pair[2], actual, pair[2]) == actual, name .. ": repeated observation")
      end
    end
  end
  assert(#failures == 0, vim.inspect(failures))

  local texts = { "" }
  local level = { "" }
  for _ = 1, 4 do
    local previous = level
    level = {}
    for _, text in ipairs(previous) do
      for _, record in ipairs { "lil\n", "wang\n" } do
        table.insert(level, text .. record)
      end
    end
    vim.list_extend(texts, level)
  end
  for _, base in ipairs(texts) do
    for _, target in ipairs(texts) do
      local parts = {}
      for part in module.prepare(base, target, base) do
        table.insert(parts, module.resolve(unpack(part)))
      end
      local actual = string.sub(table.concat(parts), 1, -2)
      assert(actual == target, vim.inspect { base = base, target = target, actual = actual })
    end
  end
end)
