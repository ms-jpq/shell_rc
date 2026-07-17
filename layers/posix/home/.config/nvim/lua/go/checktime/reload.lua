local lib = require "go.lib"
local snapshot = require "go.checktime.snapshot"

local M = {}

local MAX_WRITE_RETRIES = 3
local RECOVERY_DIR = vim.fs.joinpath(vim.fn.stdpath "state", "checktime")

local slice = function(lines, first, last)
  if first > last then
    return {}
  end

  ---@cast first integer
  ---@cast last integer
  return vim.list_slice(lines, first, last)
end

local hunk_span = function(hunk)
  local old_start, old_count, new_start, new_count = unpack(hunk)
  local old_first = old_start + (old_count == 0 and 1 or 0)
  local old_last = old_start + old_count - 1
  local new_last = new_start + new_count - 1

  return old_first, old_last, old_count, new_start, new_last, new_count
end

local relocate_row = function(row, hunks)
  local shift = 0

  for _, hunk in ipairs(hunks) do
    local old_first, old_last, old_count, _, _, new_count = hunk_span(hunk)

    if row < old_first then
      break
    elseif old_count == 0 then
      shift = shift + new_count
    elseif row > old_last then
      shift = shift + new_count - old_count
    else
      local offset = math.min(row - old_first, math.max(new_count - 1, 0))
      return old_first + shift + offset
    end
  end

  return row + shift
end

local hold_positions = function(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local views = vim.iter(vim.api.nvim_list_wins()):fold({}, function(acc, win)
    if vim.api.nvim_win_get_buf(win) == buf then
      acc[win] = vim.api.nvim_win_call(win, vim.fn.winsaveview)
    end
    return acc
  end)

  return function(hunks)
    local count = vim.api.nvim_buf_line_count(buf)
    local clamp = function(row)
      return math.max(1, math.min(relocate_row(row, hunks), count))
    end

    for win, view in pairs(views) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        view.lnum = clamp(view.lnum)
        view.topline = clamp(view.topline)

        local line = unpack(vim.api.nvim_buf_get_lines(buf, view.lnum - 1, view.lnum, true))
        view.col = math.min(view.col, #line)

        vim.api.nvim_win_call(win, function()
          vim.fn.winrestview(view)
        end)
      end
    end
  end
end

local text = function(lines)
  return #lines == 0 and "" or table.concat(lines, lib.LF) .. lib.LF
end

local diff = function(before, after)
  return vim.text.diff(text(before), text(after), { result_type = "indices" })
end

local changes = function(base, lines)
  return vim
    .iter(diff(base, lines))
    :map(function(hunk)
      local first, _, count, new_start, new_last = hunk_span(hunk)
      return { first = first, last = first + count, lines = slice(lines, new_start, new_last) }
    end)
    :totable()
end

local overlaps = function(change, first, last)
  if change.first == change.last and first == last then
    return change.first == first
  elseif change.first == change.last then
    return first < change.first and change.first < last
  elseif first == last then
    return change.first < first and first < change.last
  end
  return change.first < last and first < change.last
end

local apply_changes = function(base, changes, first, last)
  local merged = slice(base, first, last - 1)

  for change in vim.iter(changes):rev() do
    local start = change.first - first

    for _ = change.first, change.last - 1 do
      table.remove(merged, start + 1)
    end
    for index = #change.lines, 1, -1 do
      table.insert(merged, start + 1, change.lines[index])
    end
  end

  return merged
end

local next_group = function(local_changes, remote_changes, local_i, remote_i)
  local local_change = local_changes[local_i]
  local remote_change = remote_changes[remote_i]
  local first =
    math.min(local_change and local_change.first or math.huge, remote_change and remote_change.first or math.huge)
  local group = { first = first, last = first, local_changes = {}, remote_changes = {} }

  local add = function(change, group_changes)
    group.last = math.max(group.last, change.last)
    table.insert(group_changes, change)
  end

  local take = function(changes, index, group_changes)
    local change = changes[index]
    if change and overlaps(change, group.first, group.last) then
      add(change, group_changes)
      return index + 1
    end
    return index
  end

  if local_change and local_change.first == first then
    add(local_change, group.local_changes)
    local_i = local_i + 1
  else
    add(remote_change, group.remote_changes)
    remote_i = remote_i + 1
  end

  while true do
    local before_local, before_remote = local_i, remote_i
    local_i = take(local_changes, local_i, group.local_changes)
    remote_i = take(remote_changes, remote_i, group.remote_changes)
    if local_i == before_local and remote_i == before_remote then
      return group, local_i, remote_i
    end
  end
end

local resolve_group = function(base, group)
  if #group.local_changes == 0 then
    return apply_changes(base, group.remote_changes, group.first, group.last), false
  elseif #group.remote_changes == 0 then
    return apply_changes(base, group.local_changes, group.first, group.last), false
  end

  local local_lines = apply_changes(base, group.local_changes, group.first, group.last)
  local remote_lines = apply_changes(base, group.remote_changes, group.first, group.last)
  local same = vim.deep_equal(local_lines, remote_lines)
  return same and local_lines or remote_lines, not same
end

local merge = function(base, local_lines, remote_lines)
  local local_changes = changes(base, local_lines)
  local remote_changes = changes(base, remote_lines)
  local local_i, remote_i = 1, 1
  local row = 1
  local merged = {}
  local conflicted = false

  while local_changes[local_i] or remote_changes[remote_i] do
    local group
    group, local_i, remote_i = next_group(local_changes, remote_changes, local_i, remote_i)
    vim.list_extend(merged, slice(base, row, group.first - 1))
    local lines, conflict = resolve_group(base, group)
    vim.list_extend(merged, lines)
    conflicted = conflicted or conflict
    row = group.last
  end

  vim.list_extend(merged, slice(base, row, #base))
  return merged, conflicted
end

---@generic T
---@param base T
---@param local_value T
---@param remote_value T
---@return T, boolean
local merge_value = function(base, local_value, remote_value)
  if remote_value == base or local_value == remote_value then
    return local_value, false
  elseif local_value == base then
    return remote_value, false
  else
    return remote_value, true
  end
end

local preserve = function(name, state)
  if vim.fn.mkdir(RECOVERY_DIR, "p") == 0 and vim.fn.isdirectory(RECOVERY_DIR) == 0 then
    return nil
  end

  local lines = vim.deepcopy(state.lines)
  if state.fileformat == "dos" then
    for index, line in pairs(lines) do
      lines[index] = line .. "\r"
    end
  end
  if state.endofline then
    table.insert(lines, "")
  end

  local path =
    vim.fs.joinpath(RECOVERY_DIR, vim.fn.sha256(name) .. "-" .. vim.fn.sha256(tostring(vim.uv.hrtime())) .. ".txt")
  local ok, ret = pcall(vim.fn.writefile, lines, path, "b")
  return ok and ret == 0 and path or nil
end

local patch_lines = function(buf, lines)
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local hunks = diff(before, lines)
  ---@cast hunks integer[][]

  if #hunks > 0 then
    vim.api.nvim_feedkeys(vim.keycode "i<C-g>u<Esc>", "nx", false)
  end

  for index, hunk in vim.iter(hunks):rev():enumerate() do
    local old_first, _, old_count, new_start, new_last = hunk_span(hunk)
    local replace = vim.list_slice(lines, new_start, new_last)
    local start = old_first - 1

    if index > 1 then
      vim.cmd.undojoin()
    end
    vim.api.nvim_buf_set_lines(buf, start, start + old_count, true, replace)
  end

  return hunks
end

local apply = function(buf, name, remote)
  local local_state = snapshot.buffer(buf)
  local base = snapshot.base(buf) or local_state
  local lines, line_conflict = merge(base.lines, local_state.lines, remote.lines)
  local endofline, endofline_conflict = merge_value(base.endofline, local_state.endofline, remote.endofline)
  local fileformat, fileformat_conflict = merge_value(base.fileformat, local_state.fileformat, remote.fileformat)
  if line_conflict or endofline_conflict or fileformat_conflict then
    local path = preserve(name, local_state)
    if not path then
      vim.notify("checktime: could not preserve local conflict", vim.log.levels.ERROR)
      return
    end
    vim.notify("checktime: preserved local conflict at " .. path, vim.log.levels.WARN)
  end

  local restore = hold_positions(buf)
  local hunks = patch_lines(buf, lines)
  restore(hunks)
  vim.bo[buf].endofline = endofline
  vim.bo[buf].fileformat = fileformat
  vim.bo[buf].modified = not vim.deep_equal(lines, remote.lines)
    or vim.bo[buf].endofline ~= remote.endofline
    or vim.bo[buf].fileformat ~= remote.fileformat

  if not vim.bo[buf].modified then
    snapshot.save(buf)
  end

  return vim.bo[buf].modified
end

M.apply = function(buf, name)
  local remote = snapshot.read(name)
  if not remote then
    return nil
  end
  return apply(buf, name, remote)
end

M.prepare_write = function(buf, name)
  if not vim.uv.fs_stat(name) then
    return snapshot.base(buf) == nil
  end

  for _ = 1, MAX_WRITE_RETRIES do
    local remote = snapshot.read(name)
    if not remote or apply(buf, name, remote) == nil then
      return false
    end

    local current = snapshot.read(name)
    if current and vim.deep_equal(remote, current) then
      return true
    end
  end

  return false
end

return M
