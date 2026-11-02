local T = require "tests.lib"

T.test({ "independent edits retain their component boundaries", timeout = 10000, isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge

  local cases = {
    {
      name = "an insertion does not consume an adjacent coalesced substitution",
      base = "a\nb\nc",
      local_text = "a\nb\nlocal\nc",
      remote_text = "a\nB\nC",
      expected = "a\nB\nlocal\nC",
      swapped = "a\nB\nlocal\nC",
    },
    {
      name = "an insertion composes with a following-row substitution",
      base = "a\nb\nc",
      local_text = "a\nlocal\nb\nc",
      remote_text = "a\nB\nc",
      expected = "a\nlocal\nB\nc",
      swapped = "a\nlocal\nB\nc",
    },
    {
      name = "disjoint character edits survive interleaved bounds",
      base = "abcdef",
      local_text = "aXbcdeF",
      remote_text = "abcDef",
      expected = "aXbcDeF",
      swapped = "aXbcDeF",
    },
    {
      name = "a character conflict does not consume a later remote edit",
      base = "abcd",
      local_text = "Abcd",
      remote_text = "ZbcD",
      expected = "AbcD",
      swapped = "ZbcD",
    },
    {
      name = "a shared insertion is applied once",
      base = "a\nb",
      local_text = "x\na\nB",
      remote_text = "x\na\nC",
      expected = "x\na\nB",
      swapped = "x\na\nC",
    },
    {
      name = "a shared character insertion is applied once",
      base = "abcd",
      local_text = "Xabcd",
      remote_text = "XabcD",
      expected = "XabcD",
      swapped = "XabcD",
    },
    {
      name = "distinct insertions at one slot preserve role order",
      base = "a\nb",
      local_text = "local\na\nb",
      remote_text = "remote\na\nb",
      expected = "local\nremote\na\nb",
      swapped = "remote\nlocal\na\nb",
    },
    {
      name = "a row insertion composes at a deletion start",
      base = "a\nb\nc",
      local_text = "a\ninserted\nb\nc",
      remote_text = "a\nc",
      expected = "a\ninserted\nc",
      swapped = "a\ninserted\nc",
    },
    {
      name = "a row insertion composes at a deletion finish",
      base = "a\nb\nc",
      local_text = "a\nb\ninserted\nc",
      remote_text = "a\nc",
      expected = "a\ninserted\nc",
      swapped = "a\ninserted\nc",
    },
    {
      name = "a character insertion composes at a deletion start",
      base = "ab",
      local_text = "Xab",
      remote_text = "b",
      expected = "Xb",
      swapped = "Xb",
    },
    {
      name = "a character insertion wins an anchor conflict",
      base = "ab",
      local_text = "aXb",
      remote_text = "b",
      expected = "aXb",
      swapped = "b",
    },
    {
      name = "extending a repeated record conflicts with deleting it",
      base = "a",
      local_text = "",
      remote_text = "a\na",
      expected = "",
      swapped = "a\na",
    },
    {
      name = "commuting fragments retain the operational hybrid",
      base = "c",
      local_text = "L",
      remote_text = "R-conflict",
      expected = "R-Lonflict",
      swapped = "R-Lonflict",
    },
  }

  for _, case in pairs(cases) do
    local actual = merge(case.base, case.local_text, case.remote_text)
    assert(actual == case.expected, vim.inspect { case = case, actual = actual })

    local swapped = merge(case.base, case.remote_text, case.local_text)
    assert(swapped == case.swapped, vim.inspect { case = case, swapped = swapped })
  end
end)
