local async = require "goto.async"
local diff = require "goto.fs_reconcile.hunks.diff"
local lib = require "goto.lib"

local M = {}

---@class FsReconcileReplacement
---@field changes FsReconcileHunk[]
---@field endofline boolean

local buffer_lines = function(records)
  return vim
    .iter(records)
    :map(function(record)
      return vim.endswith(record, lib.LF) and string.sub(record, 1, -#lib.LF - 1) or record
    end)
    :totable()
end

---@param before string
---@param after string
---@return integer[][]
local indices = function(before, after)
  local result = assert(vim.text.diff(before, after, { result_type = "indices" }))
  ---@cast result integer[][]
  return result
end

---@param current FsReconcileBuffer
---@param text string
---@return FsReconcileReplacement
M.plan = function(current, text)
  local changes = async.work(indices, current.text, text)
  return {
    changes = diff.changes(diff.records(text), changes),
    endofline = vim.endswith(text, lib.LF),
  }
end

---@param buf integer
---@param replacement FsReconcileReplacement
---@param mark fun(start: integer, finish: integer)
M.run = function(buf, replacement, mark)
  local in_insert = vim.api.nvim_get_current_buf() == buf and lib.is_insert(vim.api.nvim_get_mode().mode)

  vim.api.nvim_buf_call(buf, function()
    for index, hunk in vim.iter(replacement.changes):rev():enumerate() do
      if index == #replacement.changes then
        if not in_insert then
          vim.opt_local.undolevels = vim.bo.undolevels
        end
      else
        vim.cmd.undojoin()
      end

      local lines = buffer_lines(hunk.lines)
      vim.api.nvim_buf_set_lines(buf, hunk.start, hunk.finish, true, lines)
      if #lines > 0 then
        mark(hunk.start, hunk.start + #lines)
      end
    end

    vim.bo[buf].endofline = replacement.endofline
  end)
end

return M
