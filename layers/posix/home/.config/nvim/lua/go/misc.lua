local lib = require "go"

-- set terminal title
vim.opt.title = true
vim.opt.titlestring = [[-- %t]]

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = lib.group,
  pattern = { "*.txt" },
  callback = function()
    if vim.bo.filetype == "help" then
      vim.cmd.wincmd "T"
    end
  end,
})

-- Go.reap = function()
--   local children = vim.api.nvim_get_proc_children(pid)
--   for _, child in ipairs(children) do
--     -- local proc = vim.api.nvim_get_proc(child) or {}
--     vim.uv.kill(child, vim.uv.constants.SIGTERM)
--   end
-- end
