vim.bo.commentstring = "# %s"
local buf = vim.api.nvim_get_current_buf()

vim.schedule(function()
  if vim.api.nvim_buf_is_valid(buf) then
    vim.bo[buf].syntax = "sh"
  end
end)
