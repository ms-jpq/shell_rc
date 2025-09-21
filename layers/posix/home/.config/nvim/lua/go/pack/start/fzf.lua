-- vim.env.FZF_DEFAULT_OPTS = vim.env.FZF_DEFAULT_OPTS .. " --no-border"

vim.g.fzf_layout = {
  window = {
    width = 0.96,
    height = 0.96
  }
}

vim.g.fzf_vim = {
  buffers_jump = true,
  grep_multi_line = true,
  preview_window = {"right:wrap"}
}

vim.keymap.set("n", [[<leader>b]], [[<cmd>Buffers<cr>]], {noremap = true})
vim.keymap.set("n", [[<leader>B]], [[<cmd>Jumps<cr>]], {noremap = true})
vim.keymap.set("n", [[<leader>m]], [[<cmd>Marks<cr>]], {noremap = true})

vim.keymap.set("n", [[<leader>o]], [[<cmd>BLines<cr>]], {noremap = true})
vim.keymap.set("n", [[<leader>p]], [[<cmd>Files<cr>]], {noremap = true})

vim.keymap.set("n", [[<leader>y]], [[<cmd>GFiles?<cr>]], {noremap = true})
vim.keymap.set("n", [[<leader>Y]], [[<cmd>GFiles<cr>]], {noremap = true})

vim.keymap.set("n", [[<leader>O]], [[<cmd>RG<cr>]], {noremap = true})

-- vim.api.nvim_create_user_command(
--   "FTdetect",
--   function()
--     vim.cmd [[filetype detect]]
--   end,
--   {
--     force = true,
--     bang = true,
--     nargs = true
--   }
-- )

vim.cmd [[command! -bang -nargs=* RG call fzf#vim#grep2("rg --fixed-strings --column --line-number --no-heading --color=always --smart-case -- ", <q-args>, fzf#vim#with_preview(), <bang>0)]]
