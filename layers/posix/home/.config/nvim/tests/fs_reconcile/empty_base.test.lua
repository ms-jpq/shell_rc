local T = require "tests.lib"

T.test({ "empty base keeps agreement and containment, otherwise joins buffer before disk", isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge
  local hunks = require "goto.fs_reconcile.hunks"
  local cases = {
    { left = "", right = "", expected = "" },
    { left = "", right = "dogs", expected = "dogs" },
    { left = "dogs", right = "dogs", expected = "dogs" },
    { left = "dog", right = "dogs", expected = "dogs" },
    { left = "dogs", right = "small dogs", expected = "small dogs" },
    { left = "dogs", right = "dogs\npups", expected = "dogs\npups" },
    { left = "dogs", right = "pups\ndogs", expected = "pups\ndogs" },
    { left = "🐕", right = "🐕🐩", expected = "🐕🐩" },
    { left = "🐕", right = "🐩🐕", expected = "🐩🐕" },
    { left = "dogs", right = "cats" },
    { left = "dogs", right = "small dogs bark" },
    { left = "\n\n", right = "dogs" },
  }
  for _, case in ipairs(cases) do
    for _, pair in ipairs { { case.left, case.right }, { case.right, case.left } } do
      local left, right = unpack(pair)
      local expected = case.expected or left .. "\n" .. right
      T.eq(expected, merge("", left, right), case)
      local result = hunks.merge(
        { text = "", endofline = false },
        { text = left, endofline = true },
        { text = right, endofline = true }
      )
      T.eq(expected, result.text, case)
    end
  end
end)
