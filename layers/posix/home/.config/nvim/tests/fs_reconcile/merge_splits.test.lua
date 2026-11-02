local T = require "tests.lib"

T.test({ "line splits and joins compose with independent edits", timeout = 10000, isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge

  local cases = {
    { base = "dog runs", local_text = "dog\nruns", remote = "dog walks", expected = "dog\nwalks" },
    { base = "dog\nruns", local_text = "dog runs", remote = "dog\nwalks", expected = "dog walks" },
    { base = "café runs", local_text = "café\nruns", remote = "café walks", expected = "café\nwalks" },
    { base = "dog runs", local_text = "dog\n\nruns", remote = "dog walks", expected = "dog\n\nwalks" },
    { base = "dog\n\nruns", local_text = "dog runs", remote = "dog\n\nwalks", expected = "dog walks" },
    { base = "dog runs", local_text = "dog\nruns", remote = "DOG runs", expected = "DOG\nruns" },
    { base = "dog runs", local_text = "dog\nruns\n", remote = "dog walks", expected = "dog\nwalks\n" },
    { base = "dog\nruns\n", local_text = "dog runs", remote = "dog\nwalks\n", expected = "dog walks" },
  }

  for _, case in ipairs(cases) do
    for _, padding in ipairs { { "", "" }, { "before\n", "" }, { "", "\nafter" }, { "before\n", "\nafter" } } do
      local prefix, suffix = unpack(padding)
      local base = prefix .. case.base .. suffix
      local left = prefix .. case.local_text .. suffix
      local right = prefix .. case.remote .. suffix
      local expected = prefix .. case.expected .. suffix
      for _, pair in ipairs { { left, right }, { right, left } } do
        local local_text, remote = unpack(pair)
        local actual = merge(base, local_text, remote)
        assert(actual == expected, vim.inspect { case = case, pair = pair, actual = actual, expected = expected })
        assert(merge(remote, actual, remote) == actual)
        assert(merge(remote, actual, actual) == actual)
      end
    end
  end

  assert(merge("dog walks", "dog\nwalks", "dog jumps") == "dog\njumps")
  assert(merge("dog\nwalks", "dog walks", "dog\njumps") == "dog jumps")
  assert(merge("dog runs", "dog\nruns", "dog\truns") == "dog\nruns")
  assert(merge("dog runs", "dog\truns", "dog\nruns") == "dog\truns")
  assert(merge("dog\ncat", "\ncat", "hound\ncat") == "\ncat")
  assert(merge("dog\ncat", "hound\ncat", "\ncat") == "hound\ncat")

  for _, case in ipairs {
    { base = "dog\ncat", local_text = "cat", remote = "new dog\ncat" },
    { base = "cat\ndog", local_text = "cat", remote = "cat\nnew dog" },
    { base = "before\ndog\nafter", local_text = "before\nafter", remote = "before\nnew dog\nafter" },
    { base = "dog", local_text = "", remote = "new dog" },
  } do
    assert(merge(case.base, case.local_text, case.remote) == case.local_text, vim.inspect(case))
    assert(merge(case.base, case.remote, case.local_text) == case.remote, vim.inspect(case))
  end
end)
