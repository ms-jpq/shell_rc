local M = {}

local registered = {}

M.register = function(commands)
  for name, command in pairs(commands) do
    registered[name] = command
  end
end

vim.api.nvim_create_user_command("Go", function(args)
  registered[args.args]()
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(registered)
  end,
})

return M
