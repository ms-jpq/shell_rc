local M

M.visual_lines = function()
  local mode = vim.api.nvim_get_mode().mode
  return vim.fn.getregion(vim.fn.getpos "v", vim.fn.getcurpos(), { type = mode })
end

return M
