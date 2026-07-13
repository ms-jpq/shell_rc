-- vim.env.FZF_DEFAULT_OPTS = vim.env.FZF_DEFAULT_OPTS .. " --no-border"

local fzf = require "go.pack.fzf.lib"

vim.g.fzf_layout = {
  window = {
    width = 0.96,
    height = 0.96,
  },
}

vim.keymap.set({ "n" }, [[<leader>b]], fzf.buffers)
vim.keymap.set({ "n" }, [[<leader>f]], fzf.files)
vim.keymap.set({ "n" }, [[<leader>G]], fzf.git_files)
vim.keymap.set({ "n" }, [[<leader>g]], fzf.git_status)

vim.keymap.set({ "n" }, [[<leader>j]], function()
  fzf.marks(vim.fn.getmarklist(vim.api.nvim_get_current_buf()), "%l")
end)

vim.keymap.set({ "n" }, [[<leader>J]], function()
  fzf.marks(vim.fn.getmarklist(), "%u")
end)

vim.keymap.set({ "n" }, [[<leader>?]], function()
  fzf.rg_search()
end)

vim.keymap.set({ "n" }, [[<leader>/]], function()
  local buf = vim.api.nvim_get_current_buf()
  fzf.blines_search(buf)
end)

return fzf
