local lib = require "go.lib"

local M = {}

local in_cwd = function(cwd, name)
  if name == "" or string.match(name, [[^%w[%w+.-]*://]]) then
    return false
  end

  local joined = string.sub(name, 1, 1) == lib.os.sep and name or vim.fs.joinpath(cwd, name)
  local norm = vim.fs.normalize(joined, { expand_env = false })
  return vim.fs.relpath(cwd, norm) ~= nil
end

M.prune_buffers = function(cwd)
  cwd = cwd or vim.fn.getcwd()
  vim
    .iter(vim.api.nvim_list_bufs())
    :filter(function(buf)
      if not vim.bo[buf].buflisted or vim.bo[buf].modified then
        return false
      end
      local name = vim.api.nvim_buf_get_name(buf)
      return not in_cwd(cwd, name)
    end)
    :each(function(buf)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
end

M.hide_external_windows = function(cwd)
  local hidden = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if not in_cwd(cwd, name) then
      local scratch = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_call(win, function()
        vim.cmd("keepalt buffer " .. scratch)
      end)
      table.insert(hidden, { win, buf, scratch })
    end
  end

  return function()
    for _, item in ipairs(hidden) do
      local win, buf, scratch = unpack(item)
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_win_call(win, function()
          vim.cmd("keepalt buffer " .. buf)
        end)
      end
      if vim.api.nvim_buf_is_valid(scratch) then
        vim.api.nvim_buf_delete(scratch, { force = true })
      end
    end
  end
end

M.scrub_session = function(cwd, path)
  local acc = {}
  for _, line in ipairs(vim.fn.readfile(path)) do
    local name = string.match(line, [[^balt%s+(.+)$]])
    if name then
      name = string.gsub(name, [[\(.)]], [[%1]])
      if in_cwd(cwd, name) then
        table.insert(acc, line)
      end
    else
      table.insert(acc, line)
    end
  end

  vim.fn.writefile(acc, path)
end

return M
