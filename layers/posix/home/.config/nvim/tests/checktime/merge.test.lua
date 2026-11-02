local T = require "tests.lib"

local words = function(separator, depth)
  local result = { "" }
  local level = { "" }
  for _ = 1, depth do
    local previous = level
    level = {}
    for _, prefix in ipairs(previous) do
      for _, character in ipairs { "a", "b" } do
        table.insert(level, prefix .. (prefix == "" and "" or separator) .. character)
      end
    end
    vim.list_extend(result, level)
  end
  return result
end

for _, separator in ipairs { "", "\n" } do
  T.test({ (separator == "" and "character" or "line") .. " merge identities and repeated observations" }, function()
    local merge = require("goto.fs_reconcile.hunks.merge").merge
    local texts = words(separator, 3)
    for _, base in ipairs(texts) do
      for _, left in ipairs(texts) do
        T.eq(left, merge(base, left, base))
        T.eq(left, merge(base, base, left))
        T.eq(left, merge(base, left, left))
        for _, right in ipairs(texts) do
          local merged = merge(base, left, right)
          T.eq(merged, merge(right, merged, right))
        end
      end
    end
  end)
end

T.test({ "every independent insertion and deletion commutes" }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge
  local base = { "dog", "lil", "wang" }
  local text = function(value)
    return table.concat(value, "\n")
  end
  for left_slot = 0, #base do
    for right_slot = 0, #base do
      if left_slot ~= right_slot then
        local left, right = vim.list_slice(base), vim.list_slice(base)
        table.insert(left, left_slot + 1, "local")
        table.insert(right, right_slot + 1, "remote")
        local expected = {}
        for slot = 0, #base do
          if slot == left_slot then
            table.insert(expected, "local")
          end
          if slot == right_slot then
            table.insert(expected, "remote")
          end
          if base[slot + 1] then
            table.insert(expected, base[slot + 1])
          end
        end
        T.eq(text(expected), merge(text(base), text(left), text(right)))
      end
    end
  end
  for deleted = 1, #base do
    for replaced = 1, #base do
      if deleted ~= replaced then
        local left, right = vim.list_slice(base), vim.list_slice(base)
        table.remove(left, deleted)
        right[replaced] = "remote"
        local expected = vim.list_slice(right)
        table.remove(expected, deleted)
        T.eq(text(expected), merge(text(base), text(left), text(right)))
      end
    end
  end
end)

T.test({ "local inserted markers survive competing edits" }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge
  local texts = words("", 4)
  for _, base in ipairs(texts) do
    for slot = 0, #base do
      local left = string.sub(base, 1, slot) .. "x" .. string.sub(base, slot + 1)
      for _, right in ipairs(texts) do
        local actual = merge(base, left, right)
        assert(
          string.find(actual, "x", 1, true),
          vim.inspect { base = base, left = left, right = right, actual = actual }
        )
      end
    end
  end
end)

for _, separator in ipairs { "", "\n" } do
  T.test({ (separator == "" and "character" or "line") .. " conflicts preserve independent edits" }, function()
    local merge = require("goto.fs_reconcile.hunks.merge").merge
    local flags = { { false, false }, { false, true }, { true, false }, { true, true } }
    for _, local_changed in ipairs(flags) do
      for _, remote_changed in ipairs(flags) do
        local base, left, right, expected = { "a", "b" }, {}, {}, {}
        for row = 1, 2 do
          left[row] = local_changed[row] and ({ "L", "M" })[row] or base[row]
          right[row] = remote_changed[row] and ({ "R", "S" })[row] or base[row]
          expected[row] = local_changed[row] and left[row] or right[row]
        end
        T.eq(
          table.concat(expected, separator),
          merge(table.concat(base, separator), table.concat(left, separator), table.concat(right, separator))
        )
      end
    end
  end)
end

T.test({ "unchanged local text accepts snippet whitespace changes" }, function()
  local merge = require("goto.fs_reconcile.hunks.merge").merge
  local base = "#!/bin/bash\n\nset -o pipefail\n\ncd -- dogs\n"
  local remote = "#!/bin/bash\n\n\nset -o pipefail\n\ncd -- dogs"
  T.eq(remote, merge(base, base, remote))
end)
