local lib = require "goto.lib"

local M = {}

local is_file_name = function(name)
  return name ~= "" and not string.match(name, [[^%w[%w+.-]*://]])
end

local realpath = function(path)
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path, { expand_env = false })
end

local in_cwd = function(cwd, name)
  if not is_file_name(name) then
    return false
  end

  local joined = string.sub(name, 1, 1) == lib.os.sep and name or vim.fs.joinpath(cwd, name)
  return vim.fs.relpath(cwd, realpath(joined)) ~= nil
end

local external_buffer = function(cwd, buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return is_file_name(name) and not vim.bo[buf].modified and not in_cwd(cwd, name)
end

M.prune_session = function(cwd)
  cwd = realpath(cwd)

  for _, win in pairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)

      if external_buffer(cwd, buf) then
        local tab = vim.api.nvim_win_get_tabpage(win)

        if #vim.api.nvim_tabpage_list_wins(tab) > 1 then
          vim.api.nvim_win_close(win, true)
        elseif #vim.api.nvim_list_tabpages() > 1 then
          vim.api.nvim_set_current_tabpage(tab)
          vim.cmd.tabclose()
        else
          vim.api.nvim_set_current_win(win)
          vim.cmd.enew { mods = { keepalt = true } }
        end
      end
    end
  end

  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if external_buffer(cwd, buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

return M
