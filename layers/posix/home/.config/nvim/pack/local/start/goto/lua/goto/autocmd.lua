local async = require "goto.async"
local lib = require "goto.lib"

local M = {}

---@param fn fun()
---@param opts? vim.api.keyset.create_autocmd
M.vim_enter = function(fn, opts)
  local callback = async(fn)
  if vim.v.vim_did_enter == 1 then
    callback()
  else
    vim.api.nvim_create_autocmd({ "VimEnter" }, {
      group = opts and opts.group or lib.group,
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

M.insert_mode = function(opts, enter, leave)
  vim.api.nvim_create_autocmd(
    { "ModeChanged" },
    vim.tbl_extend("force", { group = lib.group }, opts, {
      callback = function(args)
        local event = args.data or vim.v.event
        local old = vim.fn.get(event, "old_mode", "")
        local new = vim.fn.get(event, "new_mode", "")
        local old_ins, new_ins = lib.is_insert(old), lib.is_insert(new)

        if not old_ins and new_ins then
          enter(args)
        elseif old_ins and not new_ins then
          leave(args)
        end
      end,
    })
  )
  return enter, leave
end

M.insert_leave = function(opts, leave)
  M.insert_mode(opts, function() end, leave)
  return leave
end

return M
