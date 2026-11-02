local T = require "tests.lib"

T.test({ "three-way merge preserves the agreed conflict policy", timeout = 10000, isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge

  local buffer_text = function(text)
    return vim.endswith(text, "\n") and string.sub(text, 1, -2) or text
  end

  local cases = {
    {
      base = "a\nb\nc\n",
      local_text = "a\nlocal\nc\n",
      remote_text = "a\nremote\nc\n",
      expected = "a\nlocal\nc\n",
    },
    {
      base = "a\nb\nc\nd\n",
      local_text = "a\nlocal-1\nlocal-2\nd\n",
      remote_text = "a\nremote-1\nremote-2\nd\n",
      expected = "a\nlocal-1\nlocal-2\nd\n",
    },
    {
      base = "abc\n",
      local_text = "ac\n",
      remote_text = "aXbc\n",
      expected = "aXc\n",
    },
    {
      base = "abc\n",
      local_text = "abxc\n",
      remote_text = "aBc\n",
      expected = "aBxc\n",
    },
    {
      base = "abc\n",
      local_text = "axc\n",
      remote_text = "ayc\n",
      expected = "axc\n",
    },
    {
      base = "abc\n",
      local_text = "Abc\n",
      remote_text = "aBc\n",
      expected = "ABc\n",
    },
    {
      base = "éx\n",
      local_text = "êx\n",
      remote_text = "éy\n",
      expected = "êy\n",
    },
    {
      base = "abcdef\n",
      local_text = "aXdef\n",
      remote_text = "abcdEf\n",
      expected = "aXdEf\n",
    },
    {
      base = "é\n",
      local_text = "©\n",
      remote_text = "ê\n",
      expected = "©\n",
    },
    {
      base = "a\n",
      local_text = "a\nlocal\n",
      remote_text = "a\nremote\n",
      expected = "a\nlocal\nremote\n",
    },
    {
      base = "a\n",
      local_text = "a",
      remote_text = "a\nb\n",
      expected = "a\nb\n",
    },
    {
      base = "a\nb\n",
      local_text = "x",
      remote_text = "a\n\nb\n",
      expected = "x",
    },
  }

  for _, case in ipairs(cases) do
    assert(
      merge(buffer_text(case.base), buffer_text(case.local_text), buffer_text(case.remote_text))
        == buffer_text(case.expected),
      vim.inspect(case)
    )
  end
end)
