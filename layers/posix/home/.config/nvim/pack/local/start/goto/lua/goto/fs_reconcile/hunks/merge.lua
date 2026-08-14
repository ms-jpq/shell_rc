local diff = require "goto.fs_reconcile.hunks.diff"

local M = {}

---@class FsReconcileHunkGroup
---@field local_patches FsReconcileHunk[]
---@field remote_patches FsReconcileHunk[]

local chars = function(text)
  return coroutine.wrap(function()
    local start = 1

    for index = 2, #text do
      local byte = string.byte(text, index)
      if byte < 128 or byte >= 192 then
        coroutine.yield(string.sub(text, start, index - 1))
        start = index
      end
    end
    if start <= #text then
      coroutine.yield(string.sub(text, start))
    end
  end)
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
  local patches = {}

  for _, hunk in ipairs(hunks) do
    if hunk.finish - hunk.start == #hunk.lines then
      vim.list_extend(patches, split(hunk))
    else
      table.insert(patches, hunk)
    end
  end

  return patches
end

local resizes = function(patches)
  return vim.iter(patches):any(function(patch)
    return patch.finish - patch.start ~= #patch.lines
  end)
end

local patches_text = function(patches)
  local text = {}
  for _, hunk in ipairs(patches) do
    vim.list_extend(text, hunk.lines)
  end
  return table.concat(text)
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
  return coroutine.wrap(function()
    local local_i, remote_i = 1, 1
    while local_patches[local_i] or remote_patches[remote_i] do
      local group
      group, local_i, remote_i = next_group(local_patches, remote_patches, local_i, remote_i)
      coroutine.yield(group)
    end
  end)
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
  local scan = function(patches)
    for _, hunk in ipairs(patches) do
      start = math.min(start, hunk.start)
      finish = math.max(finish, hunk.finish)
    end
  end
  scan(group.local_patches)
  scan(group.remote_patches)
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

local take_both = function(linefeed, local_text, remote_text)
  if local_text == remote_text then
    return diff.records(linefeed, local_text)
  elseif local_text == "" then
    return diff.records(linefeed, remote_text)
  elseif remote_text == "" then
    return diff.records(linefeed, local_text)
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

local split_record = function(linefeed, record)
  if vim.endswith(record, linefeed) then
    return string.sub(record, 1, -#linefeed - 1), linefeed
  end
  return record, ""
end

local character_records = function(text)
  local records = {}
  for character in chars(text) do
    table.insert(records, character .. "\n")
  end
  return records
end

local characters_text = function(records)
  return (table.concat(records):gsub("\n", ""))
end

local character_patches = function(before, after)
  local before_records = character_records(before)
  local after_records = character_records(after)
  return atomic_patches(changes(table.concat(before_records), table.concat(after_records), after_records))
end

local merge_record = function(linefeed, base, local_record, remote_record)
  if local_record == remote_record or local_record == base then
    return { remote_record }
  elseif remote_record == base then
    return { local_record }
  end

  local base_text = split_record(linefeed, base)
  local local_text, local_eol = split_record(linefeed, local_record)
  local remote_text, remote_eol = split_record(linefeed, remote_record)
  if local_eol ~= remote_eol then
    return take_both(linefeed, local_record, remote_record)
  end

  local local_patches = character_patches(base_text, local_text)
  local remote_patches = character_patches(base_text, remote_text)
  local conflicted = vim.iter(local_patches):any(function(local_patch)
    return vim.iter(remote_patches):any(function(remote_patch)
      return overlaps(local_patch, remote_patch)
    end)
  end)
  if conflicted then
    return take_both(linefeed, local_record, remote_record)
  end

  local patches = vim.list_extend(local_patches, remote_patches)
  sort(patches)
  local characters = patch(character_records(base_text), patches)
  return { characters_text(characters) .. local_eol }
end

local merge_concurrent = function(linefeed, base, group)
  if resizes(group.local_patches) or resizes(group.remote_patches) then
    return replacement(
      group,
      take_both(linefeed, patches_text(group.local_patches), patches_text(group.remote_patches))
    )
  end

  local start, finish = bounds(group)
  local before = diff.slice(base, start, finish)
  local local_lines = patch(before, relative(group.local_patches, start))
  local remote_lines = patch(before, relative(group.remote_patches, start))
  local lines = {}
  for index, record in ipairs(before) do
    vim.list_extend(lines, merge_record(linefeed, record, local_lines[index], remote_lines[index]))
  end
  return replacement(group, lines)
end

local resolve_group = function(linefeed, base, group)
  if #group.remote_patches == 0 then
    return group.local_patches
  elseif #group.local_patches == 0 then
    return group.remote_patches
  end
  return { merge_concurrent(linefeed, base, group) }
end

local merge_groups = function(linefeed, base, grouped)
  local merged = {}

  for group in grouped do
    vim.list_extend(merged, resolve_group(linefeed, base, group))
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
