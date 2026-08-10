local M = {}

---@class ChecktimeHunk
---@field start integer
---@field finish integer
---@field lines string[]
---@field slot? integer

---@class ChecktimeHunkGroup
---@field local_patches ChecktimeHunk[]
---@field remote_patches ChecktimeHunk[]

M.records = function(linefeed, text)
  if text == "" then
    return {}
  end

  local parts = vim.split(text, linefeed, { plain = true })
  local records = {}
  for index = 1, #parts - 1 do
    table.insert(records, parts[index] .. linefeed)
  end
  if string.sub(text, -#linefeed) ~= linefeed then
    table.insert(records, parts[#parts])
  end
  return records
end

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

local slice = function(lines, start, finish)
  return vim.list_slice(lines, math.floor(start + 1), math.floor(finish))
end

M.changes = function(after_records, indices)
  return vim
    .iter(indices)
    :map(function(hunk)
      local old_start, old_count, new_start, new_count = unpack(hunk)
      local start = old_start - (old_count == 0 and 0 or 1)
      return {
        start = start,
        finish = start + old_count,
        lines = slice(after_records, new_start - 1, new_start + new_count - 1),
      }
    end)
    :totable()
end

local diff = function(before, after, after_records)
  return M.changes(after_records, vim.text.diff(before, after, { result_type = "indices" }))
end

local row_patches = function(changes)
  return vim.iter(changes):map(split):flatten():totable()
end

local character_patches = function(changes)
  return vim
    .iter(changes)
    :map(function(hunk)
      return hunk.finish - hunk.start == #hunk.lines and split(hunk) or { hunk }
    end)
    :flatten()
    :totable()
end

local has_variable = function(patches)
  return vim.iter(patches):any(function(patch)
    return patch.finish - patch.start ~= #patch.lines
  end)
end

local row_hunks = function(before, after, after_records)
  return row_patches(diff(before, after, after_records))
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
  local lines = slice(base, 0, #base)

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

local row_groups = function(base, local_text, remote_text, local_lines, remote_lines)
  return groups(row_hunks(base, local_text, local_lines), row_hunks(base, remote_text, remote_lines))
end

local pick = function(group)
  if #group.remote_patches == 0 then
    return group.local_patches
  end
  return group.remote_patches
end

local resolve = function(grouped)
  local patches = {}

  for _, group in ipairs(grouped) do
    for _, remote in ipairs(group.remote_patches) do
      local conflict = vim.iter(group.local_patches):any(function(local_patch)
        return overlaps(local_patch, remote)
      end)
      if not conflict then
        table.insert(patches, remote)
      end
    end
    vim.list_extend(patches, group.local_patches)
  end

  return patches
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
  local start, finish = math.huge, 0
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

local span = function(base, text)
  local start = 1
  while start <= #base and start <= #text and base[start] == text[start] do
    start = start + 1
  end

  local finish, text_finish = #base, #text
  while finish >= start and text_finish >= start and base[finish] == text[text_finish] do
    finish = finish - 1
    text_finish = text_finish - 1
  end

  return { start = start - 1, finish = finish, slot = 0 }
end

local touches = function(local_hunks, hunk)
  return hunk.finish > hunk.start
    and vim.iter(local_hunks):any(function(other)
      return other.start == other.finish and (hunk.start == other.start or hunk.finish == other.start)
    end)
end

local character_hunk = function(linefeed, base, group)
  local start, finish = bounds(group)
  local source = group.local_patches[1] or group.remote_patches[1]
  local before = slice(base, start, finish)
  local local_lines = patch(before, relative(group.local_patches, start))
  local remote_lines = patch(before, relative(group.remote_patches, start))
  local characters = chars(before)
  local local_characters = chars(local_lines)
  local remote_characters = chars(remote_lines)

  local character_text = table.concat(characters, linefeed)
  local local_character_text = table.concat(local_characters, linefeed)
  local remote_character_text = table.concat(remote_characters, linefeed)
  local local_hunks = character_patches(diff(character_text, local_character_text, local_characters))
  local remote_hunks = vim
    .iter(character_patches(diff(character_text, remote_character_text, remote_characters)))
    :filter(function(hunk)
      return not touches(local_hunks, hunk)
    end)
    :totable()
  if
    overlaps(span(characters, local_characters), span(characters, remote_characters))
    and (has_variable(local_hunks) or has_variable(remote_hunks))
  then
    return {
      start = start,
      finish = finish,
      lines = local_lines,
      slot = start == finish and source.slot or nil,
    }
  end
  local patches = resolve(groups(local_hunks, remote_hunks))
  sort(patches)
  local merged = patch(characters, patches)
  return {
    start = start,
    finish = finish,
    lines = M.records(linefeed, table.concat(merged)),
    slot = start == finish and source.slot or nil,
  }
end

local merge_hunks = function(linefeed, base, grouped)
  local merged = {}

  for _, group in ipairs(grouped) do
    if #group.local_patches > 0 and #group.remote_patches > 0 then
      table.insert(merged, character_hunk(linefeed, base, group))
    else
      vim.list_extend(merged, pick(group))
    end
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

  local base_lines = M.records(linefeed, base)
  local local_lines = M.records(linefeed, local_text)
  local remote_lines = M.records(linefeed, remote_text)
  local grouped = row_groups(base, local_text, remote_text, local_lines, remote_lines)
  local patches = merge_hunks(linefeed, base_lines, grouped)
  sort(patches)
  return table.concat(patch(base_lines, patches))
end

return M
