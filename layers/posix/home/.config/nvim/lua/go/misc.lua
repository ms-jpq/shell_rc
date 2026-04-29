vim.api.nvim_create_user_command("FTdetect", function()
  vim.cmd [[filetype detect]]
end, {})

-- Go.reap = function()
--   local children = vim.api.nvim_get_proc_children(pid)
--   for _, child in ipairs(children) do
--     -- local proc = vim.api.nvim_get_proc(child) or {}
--     vim.uv.kill(child, vim.uv.constants.SIGTERM)
--   end
-- end
