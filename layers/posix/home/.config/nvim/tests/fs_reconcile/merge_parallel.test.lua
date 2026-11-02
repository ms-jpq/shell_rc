local T = require "tests.lib"

T.test({ "parallel merge regions preserve results and task isolation", timeout = 10000 }, function()
  local async = require "goto.async"
  local hunks = require "goto.fs_reconcile.hunks"
  local merge = require "goto.fs_reconcile.hunks.merge"
  local value = function(text)
    return { text = text, endofline = true }
  end
  local parts = vim.iter(merge.prepare("dog\ncat\nbird", "DOG\ncat\nbird", "dog\ncat\nBIRD")):totable()
  assert(
    vim.deep_equal(parts, {
      { "dog\n", "DOG\n", "dog\n" },
      { "cat\n", "cat\n", "cat\n" },
      { "bird\n", "bird\n", "BIRD\n" },
    }),
    vim.inspect(parts)
  )
  for _, case in ipairs {
    { "dog\n", "dog\n", "dog\n", "dog\n" },
    { "dog\n", "DOG\n", "dog\n", "DOG\n" },
    { "dog\n", "dog\n", "DOG\n", "DOG\n" },
    { "", "dog\n", "cat\n", "dog\ncat\n" },
    { "", "dog\n", "dog\n", "dog\n" },
    { "dog\n", "", "DOG\n", "" },
    { "dog\n", "DOG\n", "", "DOG\n" },
    { "", "\n", "", "\n" },
    { "\n", "", "\n", "" },
  } do
    local base, local_text, remote, expected = unpack(case)
    assert(merge.resolve(base, local_text, remote) == expected, vim.inspect(case))
  end
  local texts = { "", "a", "b", "a\nb", "a\n\nb", "é\n犬", "dog runs", "dog\nwalks" }
  for left, local_text in ipairs(texts) do
    for right, remote in ipairs(texts) do
      local base = texts[(left + right - 2) % #texts + 1]
      local result = hunks.merge(value(base), value(local_text), value(remote))
      local expected = merge.merge(base, local_text, remote)
      assert(
        result.text == expected,
        vim.inspect { base = base, local_text = local_text, remote = remote, result = result, expected = expected }
      )
      assert(result.endofline)
    end
  end

  local base, left, right, expected = {}, {}, {}, {}
  for index = 1, 20 do
    table.insert(base, "dog" .. index .. " runs")
    table.insert(left, "DOG" .. index .. " runs")
    table.insert(right, "dog" .. index .. " walks")
    table.insert(expected, "DOG" .. index .. " walks")
  end
  local all = async.all
  local regions
  T.patch(async, "all", function(tasks)
    regions = #tasks
    return all(tasks)
  end)
  local result =
    hunks.merge(value(table.concat(base, "\n")), value(table.concat(left, "\n")), value(table.concat(right, "\n")))
  async.all = all
  assert(regions == 20, vim.inspect { regions = regions })
  assert(result.text == table.concat(expected, "\n"), vim.inspect(result))

  local done = async.future()
  local remaining = 8
  local outcomes = {}
  for index = 1, remaining do
    async.run(function()
      local ok, merged = pcall(hunks.merge, value "dog runs", value "dog\nruns", value "dog walks")
      outcomes[index] = { ok, merged }
      remaining = remaining - 1
      if remaining == 0 then
        done.resolve()
      end
    end)
  end
  done.await()
  for _, outcome in ipairs(outcomes) do
    local ok, merged = unpack(outcome)
    assert(ok, tostring(merged))
    assert(merged.text == "dog\nwalks", vim.inspect(merged))
  end
end)
