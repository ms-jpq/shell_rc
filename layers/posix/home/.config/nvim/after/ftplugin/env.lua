vim.bo.commentstring = "# %s"
local buf = vim.api.nvim_get_current_buf()

vim.schedule(function()
  vim.bo[buf].syntax = "sh"
end)
