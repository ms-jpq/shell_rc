local hunks = require "go.checktime.hunks"
local lib = require "go.lib"
local snapshot = require "go.checktime.snapshot"

local M = {}

local MAX_WRITE_RETRIES = 3
local RECOVERY_DIR = vim.fs.joinpath(vim.fn.stdpath "state", "checktime")

local hold_positions = function(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local views = vim.iter(vim.api.nvim_list_wins()):fold({}, function(acc, win)
    if vim.api.nvim_win_get_buf(win) == buf then
      acc[win] = vim.api.nvim_win_call(win, vim.fn.winsaveview)
    end
    return acc
  end)

  return function(changes)
    local count = vim.api.nvim_buf_line_count(buf)
    local clamp = function(row)
      return math.max(1, math.min(hunks.relocate(row, changes), count))
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

local preserve = function(buf, name, state)
  if vim.fn.mkdir(RECOVERY_DIR, "p") == 0 and vim.fn.isdirectory(RECOVERY_DIR) == 0 then
    return nil
  end

  local linefeed = lib.buf_linefeed(buf)
  local contents = table.concat(state.lines, linefeed)
  if state.endofline then
    contents = contents .. linefeed
  end

  local path =
    vim.fs.joinpath(RECOVERY_DIR, vim.fn.sha256(name) .. "-" .. vim.fn.sha256(tostring(vim.uv.hrtime())) .. ".txt")
  local ok, ret = pcall(vim.fn.writefile, contents, path)
  return ok and ret == 0 and path or nil
end

local patch_lines = function(buf, lines)
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local changes = hunks.changes(before, lines)
  ---@cast changes integer[][]

  if #changes > 0 then
    vim.api.nvim_feedkeys(vim.keycode "i<C-g>u<Esc>", "nx", false)
  end

  for index, diff_hunk in vim.iter(changes):rev():enumerate() do
    if index > 1 then
      vim.cmd.undojoin()
    end
    vim.api.nvim_buf_set_lines(buf, diff_hunk.start, diff_hunk.finish, true, diff_hunk.lines)
  end

  return changes
end

local apply = function(buf, name, remote)
  local local_state = snapshot.buffer(buf)
  local base = snapshot.base(buf) or local_state
  local lines, line_conflict = hunks.merge(base.lines, local_state.lines, remote.lines)
  local endofline, endofline_conflict = merge_value(base.endofline, local_state.endofline, remote.endofline)
  local fileformat, fileformat_conflict = merge_value(base.fileformat, local_state.fileformat, remote.fileformat)
  if line_conflict or endofline_conflict or fileformat_conflict then
    local path = preserve(buf, name, local_state)
    if not path then
      vim.notify("recovery failed", vim.log.levels.ERROR)
      return
    end
    vim.notify("saved " .. path, vim.log.levels.WARN)
  end

  local restore = hold_positions(buf)
  local changes = patch_lines(buf, lines)
  restore(changes)
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
  local remote, reason = snapshot.read(name)
  if not remote then
    return nil, reason == "changing"
  end
  return apply(buf, name, remote), false
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
