local view = require "goto.checktime.view"

local M = {}

---@class ChecktimeHunk
---@field start integer
---@field finish integer
---@field lines string[]
---@field slot? integer

---@class ChecktimeHunkGroup
---@field local_patches ChecktimeHunk[]
---@field remote_patches ChecktimeHunk[]

local records = function(linefeed, text)
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
  return vim.fn.split(table.concat(pieces), [[\zs]])
end

local offsets = function(characters)
  local offsets = { [0] = 0 }
  local offset = 0
  for index, character in ipairs(characters) do
    offset = offset + #character
    offsets[index] = offset
  end
  return offsets
end

local buffer_lines = function(linefeed, text)
  return vim
    .iter(records(linefeed, text))
    :map(function(record)
      return string.sub(record, -#linefeed) == linefeed and string.sub(record, 1, -#linefeed - 1) or record
    end)
    :totable()
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

local diff = function(before, after, after_records)
  return vim
    .iter(vim.text.diff(before, after, { result_type = "indices" }))
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

local row_groups = function(base, local_text, remote_text, base_lines, local_lines, remote_lines)
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
  while start <= #base and base[start] == text[start] do
    start = start + 1
  end

  local finish = #base
  while finish >= start and base[finish] == text[#text - (#base - finish)] do
    finish = finish - 1
  end

  return { start = start - 1, finish = finish, slot = 0 }
end

local replace_cursor_line = function(buf, linefeed, hunk)
  local before = unpack(vim.api.nvim_buf_get_lines(buf, hunk.start, hunk.finish, true))
  local after = unpack(buffer_lines(linefeed, table.concat(hunk.lines)))
  local before_characters = chars { before }
  local after_characters = chars { after }
  local changed = span(before_characters, after_characters)
  local suffix = #before_characters - changed.finish
  local replacement = slice(after_characters, changed.start, #after_characters - suffix)
  local bytes = offsets(before_characters)

  vim.api.nvim_buf_set_text(
    buf,
    hunk.start,
    bytes[changed.start],
    hunk.start,
    bytes[changed.finish],
    #replacement == 0 and {} or { table.concat(replacement) }
  )
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
    lines = records(linefeed, table.concat(merged)),
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

---@param eol string
---@param base string
---@param local_text string
---@param remote_text string
---@return string
M.merge = function(eol, base, local_text, remote_text)
  if local_text == base then
    return remote_text
  elseif remote_text == base then
    return local_text
  end

  local base_lines = records(eol, base)
  local local_lines = records(eol, local_text)
  local remote_lines = records(eol, remote_text)
  local grouped = row_groups(base, local_text, remote_text, base_lines, local_lines, remote_lines)
  local patches = merge_hunks(eol, base_lines, grouped)
  sort(patches)
  return table.concat(patch(base_lines, patches))
end

---@param buf integer
---@param current ChecktimeCurrent
---@param text string
---@param mark fun(start: integer, finish: integer)
M.replace = function(buf, current, text, mark)
  local patches = row_hunks(current.text, text, records(current.linefeed, text))
  local restore, rows = view.capture(buf)

  vim.api.nvim_buf_call(buf, function()
    for index, hunk in vim.iter(patches):rev():enumerate() do
      if index == #patches then
        vim.cmd [[let &undolevels=&undolevels]]
      else
        vim.cmd.undojoin()
      end

      local lines = buffer_lines(current.linefeed, table.concat(hunk.lines))
      if rows[hunk.start] and hunk.finish == hunk.start + 1 and #lines == 1 then
        replace_cursor_line(buf, current.linefeed, hunk)
      else
        vim.api.nvim_buf_set_lines(buf, hunk.start, hunk.finish, true, lines)
      end
      if #lines > 0 then
        mark(hunk.start, hunk.start + #lines)
      end
    end

    if not current.endofline then
      local count = vim.api.nvim_buf_line_count(buf)
      local last = unpack(vim.api.nvim_buf_get_lines(buf, count - 1, count, true))
      local ending = string.sub(text, -#current.linefeed) == current.linefeed
      if ending ~= (count > 1 and last == "") then
        vim.cmd.undojoin()
        vim.api.nvim_buf_set_lines(buf, ending and -1 or -2, -1, true, ending and { "" } or {})
      end
    end
  end)
  restore()
end

return M
