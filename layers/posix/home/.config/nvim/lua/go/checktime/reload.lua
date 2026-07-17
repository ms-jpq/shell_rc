local lib = require "go.lib"

local M = {}

local MAX_RELOAD_BYTES = 2 * 1024 * 1024

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
  local views = vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win)
      return vim.api.nvim_win_get_buf(win) == buf
    end)
    :map(function(win)
      local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
      return win, view
    end)
    :totable()

  return function(hunks)
    local count = vim.api.nvim_buf_line_count(buf)
    for win, view in pairs(views) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        view.lnum = math.max(1, math.min(relocate_row(view.lnum, hunks), count))
        view.topline = math.max(1, math.min(relocate_row(view.topline, hunks), count))

        local line = unpack(vim.api.nvim_buf_get_lines(buf, view.lnum - 1, view.lnum, true))
        view.col = math.min(view.col, #line)

        vim.api.nvim_win_call(win, function()
          vim.fn.winrestview(view)
        end)
      end
    end
  end
end

local read = function(name)
  local stat = vim.uv.fs_stat(name)
  if stat and stat.size > MAX_RELOAD_BYTES then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, name)
  return ok and lines or nil
end

local patch_lines = function(buf, lines)
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local hunks = vim.text.diff(table.concat(before, lib.LF), table.concat(lines, lib.LF), { result_type = "indices" })
  ---@cast hunks integer[][]

  for hunk in vim.iter(hunks):rev() do
    local old_first, _, old_count, new_start, new_last = hunk_span(hunk)
    local replace = vim.list_slice(lines, new_start, new_last)
    local start = old_first - 1

    vim.api.nvim_buf_set_lines(buf, start, start + old_count, true, replace)
  end

  return hunks
end

M.apply = function(buf, name)
  local lines = read(name)
  if not lines then
    return
  end

  local restore = hold_positions(buf)
  local hunks = patch_lines(buf, lines)
  restore(hunks)
  vim.bo[buf].modified = false
end

return M
