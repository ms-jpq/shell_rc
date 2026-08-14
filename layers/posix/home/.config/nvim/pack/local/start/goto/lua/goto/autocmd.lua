local async = require "goto.async"
local lib = require "goto.lib"

local M = {}

M.vim_enter = function(fn)
  local callback = async(fn)
  if vim.v.vim_did_enter == 1 then
    callback()
  else
    vim.api.nvim_create_autocmd({ "VimEnter" }, {
      group = lib.group,
      once = true,
      callback = callback,
    })
  end
end

M.buf_win = function(opts, enter, leave)
  vim.api.nvim_create_autocmd(
    { "BufWinEnter", "WinEnter" },
    vim.tbl_extend("force", { group = lib.group }, opts, { callback = enter })
  )
  vim.api.nvim_create_autocmd(
    { "BufLeave" },
    vim.tbl_extend("force", { group = lib.group }, opts, { callback = leave })
  )
  return enter, leave
end

M.insert_leave = function(opts, leave)
  vim.api.nvim_create_autocmd(
    { "ModeChanged" },
    vim.tbl_extend("force", { group = lib.group }, opts, {
      callback = function(args)
        local event = args.data or vim.v.event
        local old = vim.fn.get(event, "old_mode", "")
        local new = vim.fn.get(event, "new_mode", "")
        if lib.insert_mode(old) and not lib.insert_mode(new) then
          leave(args)
        end
      end,
    })
  )
  return leave
end

M.insert_mode = function(opts, enter, leave)
  vim.api.nvim_create_autocmd(
    { "InsertEnter" },
    vim.tbl_extend("force", { group = lib.group }, opts, { callback = enter })
  )
  M.insert_leave(opts, leave)
  return enter, leave
end

return M
