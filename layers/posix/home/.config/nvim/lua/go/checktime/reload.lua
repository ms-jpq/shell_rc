local hunks = require "go.checktime.hunks"
local snapshot = require "go.checktime.snapshot"

local M = {}

local MAX_WRITE_RETRIES = 3

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

local apply = function(buf, remote)
  local local_lines = snapshot.buffer(buf)
  local base = snapshot.get(buf) or local_lines
  local lines = hunks.merge(base, local_lines, remote)

  local restore = hold_positions(buf)
  local changes = patch_lines(buf, lines)
  restore(changes)
  local modified = not vim.deep_equal(lines, remote)
  vim.bo[buf].modified = modified

  if not modified then
    snapshot.set(buf)
  end

  return modified
end

M.apply = function(buf, name)
  local remote, reason = snapshot.read(name)
  if not remote then
    return nil, reason == "changing"
  end
  return apply(buf, remote), false
end

M.buf_write_pre = function(buf, name)
  if not vim.uv.fs_stat(name) then
    return
  end

  for _ = 1, MAX_WRITE_RETRIES do
    local remote = snapshot.read(name)
    if not remote or apply(buf, remote) == nil then
      return
    end

    local current = snapshot.read(name)
    if current and vim.deep_equal(remote, current) then
      return
    end
  end
end

return M
