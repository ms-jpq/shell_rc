local hunks = require "go.checktime.hunks"
local lib = require "go.lib"
local snapshot = require "go.checktime.snapshot"

local M = {}

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

    for win, view in pairs(views) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        view.lnum = lib.clamp(1, hunks.transform(changes, view.lnum), count)
        view.topline = lib.clamp(1, hunks.transform(changes, view.topline), count)

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
  local changes = hunks.diff(before, lines)
  ---@cast changes integer[][]

  vim.api.nvim_buf_call(buf, function()
    for index, diff_hunk in vim.iter(changes):rev():enumerate() do
      if index == 1 then
        vim.cmd.normal { args = { vim.keycode "i<C-g>u<Esc>" }, bang = true }
      else
        vim.cmd.undojoin()
      end
      vim.api.nvim_buf_set_lines(buf, diff_hunk.start, diff_hunk.finish, true, diff_hunk.lines)
    end
  end)

  return changes
end

local apply = function(buf, remote)
  local local_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local base = snapshot.get(buf) or local_lines
  local lines = hunks.three_way(base, local_lines, remote)

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
  local remote = snapshot.read(name)
  if not remote then
    return nil
  end
  return apply(buf, remote)
end

M.buf_write_pre = function(buf, name)
  local remote = snapshot.read(name)
  if remote then
    apply(buf, remote)
  end
end

return M
