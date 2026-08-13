local diff = require "goto.checktime.hunks.diff"

local M = {}

---@class ChecktimeHunkGroup
---@field local_patches ChecktimeHunk[]
---@field remote_patches ChecktimeHunk[]

local chars = function(pieces)
  local text = table.concat(pieces)
  local characters = {}
  local start = 1

  for index = 2, #text do
    local byte = string.byte(text, index)
    if byte < 128 or byte >= 192 then
      table.insert(characters, string.sub(text, start, index - 1))
      start = index
    end
  end
  if start <= #text then
    table.insert(characters, string.sub(text, start))
  end

  return characters
end

local split = function(hunk)
  local old_count = hunk.finish - hunk.start
  local count = math.max(old_count, #hunk.lines)
  local patches = {}

  for index = 0, count - 1 do
    local start = hunk.start + math.min(index, old_count)
    table.insert(patches, {
      start = start,
      finish = start + (index < old_count and 1 or 0),
      lines = index < #hunk.lines and { hunk.lines[index + 1] } or {},
      slot = index < old_count and nil or index - old_count,
    })
  end

  return patches
end

local changes = function(before, after, after_records)
  local indices = vim.text.diff(before, after, { result_type = "indices" })
  ---@cast indices integer[][]
  return diff.changes(after_records, indices)
end

local atomic_patches = function(hunks)
  return vim
    .iter(hunks)
    :map(function(hunk)
      return hunk.finish - hunk.start == #hunk.lines and split(hunk) or { hunk }
    end)
    :flatten()
    :totable()
end

local variable = function(patches)
  return vim.iter(patches):any(function(patch)
    return patch.finish - patch.start ~= #patch.lines
  end)
end

local patches_lines = function(patches)
  return vim
    .iter(patches)
    :map(function(patch)
      return patch.lines
    end)
    :flatten()
    :totable()
end

local overlaps = function(left, right)
  if left.start == left.finish and right.start == right.finish then
    return left.start == right.start and left.slot == right.slot
  elseif left.start == left.finish then
    return right.start < left.start and left.start < right.finish
  elseif right.start == right.finish then
    return left.start < right.start and right.start < left.finish
  end
  return left.start < right.finish and right.start < left.finish
end

local patch = function(base, patches)
  local lines = diff.slice(base, 0, #base)

  for hunk in vim.iter(patches):rev() do
    for _ = hunk.start, hunk.finish - 1 do
      table.remove(lines, hunk.start + 1)
    end
    for index = #hunk.lines, 1, -1 do
      table.insert(lines, hunk.start + 1, hunk.lines[index])
    end
  end

  return lines
end

local next_group = function(local_patches, remote_patches, local_i, remote_i)
  local local_patch, remote_patch = local_patches[local_i], remote_patches[remote_i]
  local group = { local_patches = {}, remote_patches = {} }

  local overlaps_group = function(hunk)
    return vim.iter(group.local_patches):any(function(other)
      return overlaps(hunk, other)
    end) or vim.iter(group.remote_patches):any(function(other)
      return overlaps(hunk, other)
    end)
  end

  local take = function(patches, index, group_patches)
    local hunk = patches[index]
    if hunk and overlaps_group(hunk) then
      table.insert(group_patches, hunk)
      return true, index + 1
    end
    return false, index
  end

  if local_patch and (not remote_patch or local_patch.start <= remote_patch.start) then
    table.insert(group.local_patches, local_patch)
    local_i = local_i + 1
  else
    table.insert(group.remote_patches, remote_patch)
    remote_i = remote_i + 1
  end

  local expanded = true
  while expanded do
    local local_expanded, remote_expanded
    local_expanded, local_i = take(local_patches, local_i, group.local_patches)
    remote_expanded, remote_i = take(remote_patches, remote_i, group.remote_patches)
    expanded = local_expanded or remote_expanded
  end

  return group, local_i, remote_i
end

local groups = function(local_patches, remote_patches)
  local local_i, remote_i = 1, 1
  local grouped = {}

  while local_patches[local_i] or remote_patches[remote_i] do
    local group
    group, local_i, remote_i = next_group(local_patches, remote_patches, local_i, remote_i)
    table.insert(grouped, group)
  end

  return grouped
end

local sort = function(patches)
  table.sort(patches, function(left, right)
    if left.start ~= right.start then
      return left.start < right.start
    end
    local left_insert, right_insert = left.start == left.finish, right.start == right.finish
    if left_insert ~= right_insert then
      return left_insert
    end
    return (left.slot or 0) < (right.slot or 0)
  end)
end

local bounds = function(group)
  local first = group.local_patches[1] or group.remote_patches[1]
  local start, finish = first.start, first.finish
  for _, patches in pairs { group.local_patches, group.remote_patches } do
    for _, hunk in ipairs(patches) do
      start = math.min(start, hunk.start)
      finish = math.max(finish, hunk.finish)
    end
  end
  return start, finish
end

local relative = function(patches, start)
  return vim
    .iter(patches)
    :map(function(hunk)
      return {
        start = hunk.start - start,
        finish = hunk.finish - start,
        lines = hunk.lines,
        slot = hunk.slot,
      }
    end)
    :totable()
end

local take_both_lines = function(linefeed, local_lines, remote_lines)
  local local_text = table.concat(local_lines)
  local remote_text = table.concat(remote_lines)

  if local_text == remote_text then
    return local_lines
  elseif local_text == "" then
    return remote_lines
  elseif remote_text == "" then
    return local_lines
  end

  if not vim.endswith(local_text, linefeed) and not vim.startswith(remote_text, linefeed) then
    local_text = local_text .. linefeed
  end
  return diff.records(linefeed, local_text .. remote_text)
end

local replacement = function(group, replacement_lines)
  local start, finish = bounds(group)
  local source = group.local_patches[1] or group.remote_patches[1]

  return {
    start = start,
    finish = finish,
    lines = replacement_lines,
    slot = start == finish and source.slot or nil,
  }
end

local take_both = function(linefeed, group)
  return replacement(
    group,
    take_both_lines(linefeed, patches_lines(group.local_patches), patches_lines(group.remote_patches))
  )
end

local merge_overlap = function(linefeed, base, group)
  if variable(group.local_patches) or variable(group.remote_patches) then
    return take_both(linefeed, group)
  end

  local start, finish = bounds(group)
  local before = diff.slice(base, start, finish)
  local local_lines = patch(before, relative(group.local_patches, start))
  local remote_lines = patch(before, relative(group.remote_patches, start))
  local characters = chars(before)
  local local_characters = chars(local_lines)
  local remote_characters = chars(remote_lines)

  local character_text = table.concat(characters, linefeed)
  local local_character_text = table.concat(local_characters, linefeed)
  local remote_character_text = table.concat(remote_characters, linefeed)
  local local_hunks = atomic_patches(changes(character_text, local_character_text, local_characters))
  local remote_hunks = atomic_patches(changes(character_text, remote_character_text, remote_characters))
  local conflicted = vim.iter(local_hunks):any(function(local_hunk)
    return vim.iter(remote_hunks):any(function(remote_hunk)
      return overlaps(local_hunk, remote_hunk)
    end)
  end)

  if conflicted then
    return take_both(linefeed, group)
  end
  local patches = vim.list_extend(local_hunks, remote_hunks)
  sort(patches)
  return replacement(group, diff.records(linefeed, table.concat(patch(characters, patches))))
end

local merge_group = function(linefeed, base, group)
  if #group.remote_patches == 0 then
    return group.local_patches
  elseif #group.local_patches == 0 then
    return group.remote_patches
  end
  return { merge_overlap(linefeed, base, group) }
end

local merge_groups = function(linefeed, base, grouped)
  local merged = {}

  for _, group in ipairs(grouped) do
    vim.list_extend(merged, merge_group(linefeed, base, group))
  end

  return merged
end

---@param linefeed string
---@param base string
---@param local_text string
---@param remote_text string
---@return string
M.merge = function(linefeed, base, local_text, remote_text)
  if local_text == base then
    return remote_text
  elseif remote_text == base then
    return local_text
  end

  local base_lines = diff.records(linefeed, base)
  local local_lines = diff.records(linefeed, local_text)
  local remote_lines = diff.records(linefeed, remote_text)
  local grouped = groups(changes(base, local_text, local_lines), changes(base, remote_text, remote_lines))
  local patches = merge_groups(linefeed, base_lines, grouped)
  sort(patches)
  return table.concat(patch(base_lines, patches))
end

return M
