local async = require "go.async"
local lib = require "go.lib"

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

return M
