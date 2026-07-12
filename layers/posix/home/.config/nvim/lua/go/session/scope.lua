local lib = require "go.lib"

local M = {}

local is_file_name = function(name)
  return name ~= "" and not string.match(name, [[^%w[%w+.-]*://]])
end

local in_cwd = function(cwd, name)
  if not is_file_name(name) then
    return false
  end

  local joined = string.sub(name, 1, 1) == lib.os.sep and name or vim.fs.joinpath(cwd, name)
  local norm = vim.fs.normalize(joined, { expand_env = false })
  return vim.fs.relpath(cwd, norm) ~= nil
end

M.prune_buffers = function(cwd)
  vim
    .iter(vim.api.nvim_list_bufs())
    :filter(function(buf)
      if vim.bo[buf].modified then
        return false
      end
      local name = vim.api.nvim_buf_get_name(buf)
      return is_file_name(name) and not in_cwd(cwd, name)
    end)
    :each(function(buf)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
end

M.prune_session = function(cwd)
  for _, win in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if not in_cwd(cwd, name) and not vim.bo[buf].modified then
      local tab = vim.api.nvim_win_get_tabpage(win)
      if #vim.api.nvim_tabpage_list_wins(tab) > 1 then
        vim.api.nvim_win_close(win, true)
      else
        vim.api.nvim_set_current_tabpage(tab)
        vim.cmd.tabclose()
      end
    end
  end

  M.prune_buffers(cwd)
end

return M
