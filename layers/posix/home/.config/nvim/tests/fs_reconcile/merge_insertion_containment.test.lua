local T = require "tests.lib"

T.test({ "nested insertions are included once", timeout = 10000, isolate = false }, function()
  local hunks = require "goto.fs_reconcile.hunks"
  local merge = require "goto.fs_reconcile.hunks.merge"

  local cases = {
    { base = "dog\ncat", left = "dog\ncat pup", right = "dog\ncat pups" },
    { base = "dog\ncat", left = "pupdog\ncat", right = "pups dog\ncat" },
    { base = "dog\ncat", left = "dog\ncat pup", right = "dog\ncat big pup" },
    { base = "dog", left = "dog\ncat", right = "dog\ncat\nfox" },
    { base = "dog", left = "cat\ndog", right = "fox\ncat\ndog" },
    { base = "dog", left = "dog\n", right = "dog\n\nfox" },
    { base = "dog\ncat", left = "dog\ncat 🐕", right = "dog\ncat 🐕🐩" },
    { base = "dog\ncat", left = "dog\ncat 🐕", right = "dog\ncat 🐩 🐕" },
  }

  for _, case in ipairs(cases) do
    for _, pair in ipairs { { case.left, case.right }, { case.right, case.left } } do
      local left, right = unpack(pair)
      local actual = merge.merge(case.base, left, right)
      assert(actual == case.right, vim.inspect { case = case, pair = pair, actual = actual })
      local result = hunks.merge(
        { text = case.base, endofline = true },
        { text = left, endofline = true },
        { text = right, endofline = true }
      )
      assert(result.text == case.right, vim.inspect { case = case, pair = pair, actual = result })
    end
  end

  for _, case in ipairs {
    { left = "cat", right = "bobcat" },
    { left = "cat", right = "catfish" },
    { left = "cat", right = "fox\ncat\npup" },
  } do
    for _, pair in ipairs { { case.left, case.right }, { case.right, case.left } } do
      local left, right = unpack(pair)
      local actual = merge.merge("dog", "dog\n" .. left, "dog\n" .. right)
      assert(actual == "dog\n" .. left .. "\n" .. right, vim.inspect { pair = pair, actual = actual })
      local result = hunks.merge(
        { text = "dog", endofline = true },
        { text = "dog\n" .. left, endofline = true },
        { text = "dog\n" .. right, endofline = true }
      )
      assert(result.text == actual, vim.inspect { pair = pair, expected = actual, actual = result })
      local expected = left .. "\n" .. right .. "\ndog"
      actual = merge.merge("dog", left .. "\ndog", right .. "\ndog")
      assert(actual == expected, vim.inspect { pair = pair, expected = expected, actual = actual })
      result = hunks.merge(
        { text = "dog", endofline = true },
        { text = left .. "\ndog", endofline = true },
        { text = right .. "\ndog", endofline = true }
      )
      assert(result.text == expected, vim.inspect { pair = pair, expected = expected, actual = result })
    end
  end
end)
