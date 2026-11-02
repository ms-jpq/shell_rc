local T = require "tests.lib"

T.test({ "merges preserve canonical text and repeated observations", timeout = 10000, isolate = false }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge
  local texts = { "" }

  local append
  append = function(prefix, remaining)
    if remaining == 0 then
      table.insert(texts, prefix)
      return
    end
    for _, line in ipairs { "a", "b" } do
      append(prefix == "" and line or prefix .. "\n" .. line, remaining - 1)
    end
  end

  append("", 1)
  append("", 2)
  append("", 3)

  for _, base in ipairs(texts) do
    for _, local_text in ipairs(texts) do
      for _, remote_text in ipairs(texts) do
        local merged = merge(base, local_text, remote_text)
        assert(
          not vim.endswith(merged, "\n"),
          vim.inspect { base = base, local_text = local_text, remote_text = remote_text, merged = merged }
        )
        assert(
          merge(remote_text, merged, remote_text) == merged,
          vim.inspect { base = base, local_text = local_text, remote_text = remote_text, merged = merged }
        )
      end
    end
  end
end)
