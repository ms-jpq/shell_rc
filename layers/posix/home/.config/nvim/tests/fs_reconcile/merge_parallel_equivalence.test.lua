local T = require "tests.lib"

T.test({ "worker merges agree with synchronous merges", timeout = 10000, isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge
  local hunks = require "goto.fs_reconcile.hunks"
  local texts =
    { "", "a", "b", "a\nb", "b\na", "\na", "a\n", "a\n\nb", "dog runs", "dog\nruns", "dog\nwalks", "café\n犬" }
  for _, base in ipairs(texts) do
    for _, local_text in ipairs(texts) do
      for _, remote in ipairs(texts) do
        local expected = merge(base, local_text, remote)
        local actual = hunks.merge(
          { text = base, endofline = true },
          { text = local_text, endofline = true },
          { text = remote, endofline = true }
        ).text
        assert(
          actual == expected,
          vim.inspect { base = base, local_text = local_text, remote = remote, expected = expected, actual = actual }
        )
      end
    end
  end
end)
