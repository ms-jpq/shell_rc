local T = require "tests.lib"

T.test({ "appended newlines and nested insertions are preserved", timeout = 10000, isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge
  local hunks = require "goto.fs_reconcile.hunks"

  local cases = {
    { "append with final newline", "dogs\n\n", "dogs\n\n> question", "dogs\n\n> question\n", "dogs\n\n> question\n" },
    { "append with blank line", "dogs\n\n", "dogs\n\n> question", "dogs\n\n> question\n\n", "dogs\n\n> question\n\n" },
    { "distinct appends", "dogs\n", "dogs\nlil\n", "dogs\nwang\n", "dogs\nlil\nwang\n" },
    {
      "insertion beside replacement",
      "dogs\nlil\n",
      "dogs\nsmall lil\n",
      "dogs\nwang\nlil\n",
      "dogs\nwang\nsmall lil\n",
    },
    {
      "independent edits",
      "dogs\nlil\nwang\n",
      "dogs\nsmall lil\nwang\n",
      "dogs\nlil\nbig wang\n",
      "dogs\nsmall lil\nbig wang\n",
    },
    { "unchanged local", "dogs\n", "dogs\n", "dogs", "dogs" },
    { "identical appends", "dogs\n\n", "dogs\n\n> question\n", "dogs\n\n> question\n", "dogs\n\n> question\n" },
    { "nested text appends", "dog", "dogs", "dogs bark", "dogs bark" },
    { "nested text prepends", "dog", "small dog", "a small dog", "a small dog" },
    { "nested line prepends", "dogs\n", "lil\ndogs\n", "wang\nlil\ndogs\n", "wang\nlil\ndogs\n" },
    { "append without blank base", "dogs", "dogs\nlil", "dogs\nlil\n", "dogs\nlil\n" },
    { "deletion alongside append", "dogs\nlil\n", "dogs\n", "dogs\nlil\nwang\n", "dogs\nwang\n" },
    { "deletion alongside prepend", "lil\ndogs\n", "dogs\n", "wang\nlil\ndogs\n", "wang\ndogs\n" },
    { "unicode append", "犬", "犬🐶", "犬🐶\n", "犬🐶\n" },
    {
      "internal insertion suffix",
      "dogs\nend\n",
      "dogs\nlil\nend\n",
      "dogs\nwang\nlil\nend\n",
      "dogs\nwang\nlil\nend\n",
    },
    {
      "internal insertion prefix",
      "dogs\nend\n",
      "dogs\nlil\nend\n",
      "dogs\nlil\nwang\nend\n",
      "dogs\nlil\nwang\nend\n",
    },
    { "suffix inside a record", "dogs\nend\n", "dogs\nhotdog\nend\n", "dogs\ndog\nend\n", "dogs\nhotdog\ndog\nend\n" },
    { "character insertion", "dogs", "dog!s", "dog!!s", "dog!!s" },
  }

  local failures = {}
  local check = function(name, actual, expected)
    if actual ~= expected then
      table.insert(failures, { name = name, actual = actual, expected = expected })
    end
  end

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
    for index, case in ipairs(cases) do
      local name, base, left, right, expected = unpack(case)
      local label = mode .. ": " .. name
      local actual = fn(base, left, right)
      check(label, actual, expected)
      check(label .. ": repeated observation", fn(right, actual, right), actual)
      if index ~= 3 and index ~= 17 then
        check(label .. ": reversed inputs", fn(base, right, left), expected)
      end
    end
  end

  assert(#failures == 0, vim.inspect(failures))
end)
