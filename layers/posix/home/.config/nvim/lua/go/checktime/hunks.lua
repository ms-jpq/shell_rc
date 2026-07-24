local lib = require "go.lib"

local M = {}

local MERGE = {
  ROW = {
    atomic = true,
    local_wins = false,
    encode = function(value)
      return value
    end,
    decode = function(value)
      return value
    end,
  },
  CHAR = {
    atomic = false,
    local_wins = true,
    encode = function(lines, linefeed)
      return vim.fn.split(table.concat(lines, linefeed), [[\zs]])
    end,
    decode = function(chars, linefeed)
      local text = table.concat(chars)
      return text == "" and {} or vim.split(text, linefeed, { plain = true })
    end,
  },
}

local split = function(patch)
  local old_count = patch.finish - patch.start
  local count = math.max(old_count, #patch.lines)
  local patches = {}

  for index = 0, count - 1 do
    local start = patch.start + math.min(index, old_count)
    table.insert(patches, {
      start = start,
      finish = start + (index < old_count and 1 or 0),
      lines = index < #patch.lines and { patch.lines[index + 1] } or {},
      slot = index < old_count and nil or index - old_count,
    })
  end

  return patches
end

local slice = function(lines, start, finish)
  return vim.list_slice(lines, math.floor(start + 1), math.floor(finish))
end

local text = function(lines, linefeed)
  return #lines == 0 and "" or table.concat(lines, linefeed) .. linefeed
end

local diff = function(before, after, linefeed)
  return vim
    .iter(vim.text.diff(text(before, linefeed), text(after, linefeed), { result_type = "indices" }))
    :map(function(hunk)
      local old_start, old_count, new_start, new_count = unpack(hunk)
      local start = old_start - (old_count == 0 and 0 or 1)
      return {
        start = start,
        finish = start + old_count,
        lines = slice(after, new_start - 1, new_start + new_count - 1),
      }
    end)
    :totable()
end

local diff_patches = function(codec, before, after, linefeed)
  local changes = diff(before, after, linefeed)
  if codec.atomic then
    return vim.iter(changes):map(split):flatten():totable()
  end
  return changes
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

local apply = function(base, patches)
  local lines = slice(base, 0, #base)

  for patch in vim.iter(patches):rev() do
    for _ = patch.start, patch.finish - 1 do
      table.remove(lines, patch.start + 1)
    end
    for index = #patch.lines, 1, -1 do
      table.insert(lines, patch.start + 1, patch.lines[index])
    end
  end

  return lines
end

local next_group = function(local_patches, remote_patches, local_i, remote_i)
  local local_patch, remote_patch = local_patches[local_i], remote_patches[remote_i]
  local group = { local_patches = {}, remote_patches = {} }

  local overlaps_group = function(patch)
    return vim.iter(group.local_patches):any(function(other)
      return overlaps(patch, other)
    end) or vim.iter(group.remote_patches):any(function(other)
      return overlaps(patch, other)
    end)
  end

  local take = function(patches, index, group_patches)
    local patch = patches[index]
    if patch and overlaps_group(patch) then
      table.insert(group_patches, patch)
      return index + 1
    end
    return index
  end

  if local_patch and (not remote_patch or local_patch.start <= remote_patch.start) then
    table.insert(group.local_patches, local_patch)
    local_i = local_i + 1
  else
    table.insert(group.remote_patches, remote_patch)
    remote_i = remote_i + 1
  end

  while true do
    local before_local, before_remote = local_i, remote_i
    local_i = take(local_patches, local_i, group.local_patches)
    remote_i = take(remote_patches, remote_i, group.remote_patches)
    if local_i == before_local and remote_i == before_remote then
      return group, local_i, remote_i
    end
  end
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

local diff_groups = function(codec, base, local_lines, remote_lines, linefeed)
  return groups(diff_patches(codec, base, local_lines, linefeed), diff_patches(codec, base, remote_lines, linefeed))
end

local resolve = function(grouped, local_wins)
  local patches = {}

  for _, group in ipairs(grouped) do
    local selected = group.remote_patches
    if #selected == 0 or (local_wins and #group.local_patches > 0) then
      selected = group.local_patches
    end
    vim.list_extend(patches, selected)
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

local reconcile = function(codec, base, local_lines, remote_lines, linefeed)
  local patches = resolve(diff_groups(codec, base, local_lines, remote_lines, linefeed), codec.local_wins)
  sort(patches)
  return apply(base, patches)
end

local bounds = function(group)
  local start, finish = math.huge, 0
  for _, patches in pairs { group.local_patches, group.remote_patches } do
    for _, patch in ipairs(patches) do
      start = math.min(start, patch.start)
      finish = math.max(finish, patch.finish)
    end
  end
  return start, finish
end

local relative = function(patches, start)
  return vim
    .iter(patches)
    :map(function(patch)
      return {
        start = patch.start - start,
        finish = patch.finish - start,
        lines = patch.lines,
        slot = patch.slot,
      }
    end)
    :totable()
end

local char_merge = function(base, group, linefeed)
  local start, finish = bounds(group)
  local before = slice(base, start, finish)
  local local_lines = apply(before, relative(group.local_patches, start))
  local remote_lines = apply(before, relative(group.remote_patches, start))
  local codec = MERGE.CHAR
  local merged = reconcile(
    codec,
    codec.encode(before, linefeed),
    codec.encode(local_lines, linefeed),
    codec.encode(remote_lines, linefeed),
    linefeed
  )
  return { { start = start, finish = finish, lines = codec.decode(merged, linefeed) } }
end

local plan = function(grouped, row)
  local configs = {}
  for _, group in ipairs(grouped) do
    table.insert(configs, { type = MERGE.ROW, group = group })
  end

  if not row then
    return configs
  end

  local shift = 0
  for _, config in ipairs(configs) do
    local group = config.group
    for _, patch in ipairs(group.local_patches) do
      local first = patch.start + shift + 1
      local last = first + #patch.lines
      if first <= row and row < last then
        config.type = MERGE.CHAR
        return configs
      end
      shift = shift + #patch.lines - (patch.finish - patch.start)
    end
  end

  return configs
end

local compile = function(base, configs, linefeed)
  local patches = {}

  for _, config in ipairs(configs) do
    if config.type == MERGE.ROW then
      vim.list_extend(patches, resolve({ config.group }, config.type.local_wins))
    elseif config.type == MERGE.CHAR then
      vim.list_extend(patches, char_merge(base, config.group, linefeed))
    else
      error "unknown merge type"
    end
  end

  return patches
end

M.merge = function(base, local_lines, remote_lines, pos, eol)
  local row = unpack(pos)
  eol = eol or lib.LF
  local grouped = diff_groups(MERGE.ROW, base, local_lines, remote_lines, eol)
  local merged = compile(base, plan(grouped, row), eol)
  sort(merged)
  return apply(base, merged)
end

M.replace = function(buf, lines, mark)
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local patches = diff_patches(MERGE.ROW, before, lines, lib.buf_linefeed(buf))

  vim.api.nvim_buf_call(buf, function()
    for index, patch in vim.iter(patches):rev():enumerate() do
      if index == #patches then
        vim.cmd [[let &undolevels=&undolevels]]
      else
        vim.cmd.undojoin()
      end
      vim.api.nvim_buf_set_lines(buf, patch.start, patch.finish, true, patch.lines)
      if #patch.lines > 0 then
        mark(patch.start, patch.start + #patch.lines)
      end
    end
  end)
end

return M
