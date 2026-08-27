local async = require "goto.async"
local diff = require "goto.fs_reconcile.hunks.diff"
local lib = require "goto.lib"
local merge = require "goto.fs_reconcile.hunks.merge"
local util = require "goto.fs_reconcile.util"

local M = {}

---@class FsReconcileReplacement
---@field changes FsReconcileHunk[]
---@field endofline boolean

---@param current FsReconcileBuffer
---@param target FsReconcileBuffer
---@return FsReconcileReplacement
M.plan = function(current, target)
  local changes = async.work(diff.worker, current.text, target.text)
  if current.text == "" and target.text ~= "" then
    changes[1].finish = 1
  end
  return { changes = changes, endofline = target.endofline }
end

---@param buf integer
---@param replacement FsReconcileReplacement
---@param mark fun(start: integer, finish: integer)
M.apply = function(buf, replacement, mark)
  local in_insert = vim.api.nvim_get_current_buf() == buf and lib.is_insert(vim.api.nvim_get_mode().mode)
  local views = {}
  for _, win in pairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      views[win] = vim.api.nvim_win_call(win, vim.fn.winsaveview)
    end
  end

  vim.api.nvim_buf_call(buf, function()
    for index, hunk in vim.iter(replacement.changes):rev():enumerate() do
      if index == #replacement.changes then
        if not in_insert then
          vim.opt_local.undolevels = vim.bo.undolevels
        end
      else
        vim.cmd.undojoin()
      end

      local lines = vim
        .iter(hunk.lines)
        :map(function(record)
          return vim.endswith(record, lib.LF) and string.sub(record, 1, -#lib.LF - 1) or record
        end)
        :totable()
      vim.api.nvim_buf_set_lines(buf, hunk.start, hunk.finish, true, lines)
      mark(hunk.start, hunk.start + #lines)
    end
    vim.bo[buf].endofline = replacement.endofline
  end)

  for win, view in pairs(views) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview(view)
      end)
    end
  end
end

---@param base FsReconcileBuffer
---@param local_value FsReconcileBuffer
---@param remote FsReconcileBuffer
---@return FsReconcileBuffer
M.merge = function(base, local_value, remote)
  local text
  if local_value.text == base.text then
    text = remote.text
  elseif remote.text == base.text then
    text = local_value.text
  else
    text = async.work(merge.worker, base.text, local_value.text, remote.text)
  end

  return { text = text, endofline = util.merge_endofline(base, local_value, remote) }
end

return M
