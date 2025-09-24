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

vim.keymap.set("n", [[<leader>f]], [[<cmd>Files<cr>]], {noremap = true})

vim.keymap.set("n", [[<leader>g]], [[<cmd>GFiles?<cr>]], {noremap = true})
vim.keymap.set("n", [[<leader>G]], [[<cmd>GFiles<cr>]], {noremap = true})

vim.keymap.set("n", [[<leader>/]], [[<cmd>BL<cr>]], {noremap = true})
vim.keymap.set("n", [[<leader>?]], [[<cmd>RG<cr>]], {noremap = true})

vim.api.nvim_create_user_command(
  "RG",
  function(opts)
    local cmd = [[rg --fixed-strings --column --line-number --no-heading --color=always --smart-case --]]
    vim.fn["fzf#vim#grep2"](cmd, opts.args, vim.fn["fzf#vim#with_preview"](), opts.bang)
  end,
  {
    force = true,
    bang = true,
    nargs = "*"
  }
)
