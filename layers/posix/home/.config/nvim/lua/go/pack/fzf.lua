-- vim.env.FZF_DEFAULT_OPTS = vim.env.FZF_DEFAULT_OPTS .. " --no-border"

vim.g.fzf_layout = {
  window = {
    width = 0.96,
    height = 0.96,
  },
}

vim.g.fzf_vim = {
  buffers_jump = true,
  grep_multi_line = true,
  preview_window = { "right:wrap" },
}

vim.keymap.set({ "n" }, [[<leader>|]], [[<cmd>Maps!<cr>]])
vim.keymap.set({ "n" }, [[<leader>\]], [[<cmd>Commands!<cr>]])

vim.keymap.set({ "n" }, [[<leader>b]], [[<cmd>Buffers!<cr>]])

do
  local az = "abcdefghijklmnopqrstuvwxyz"
  local AZ = string.upper(az)
  local azt = vim.split(az, "", { plain = true })
  local AZT = vim.split(AZ, "", { plain = true })
  vim.keymap.set({ "n" }, [[<leader>j]], [[<cmd>Marks! ]] .. table.concat(azt, " ") .. [[<cr>]])
  vim.keymap.set({ "n" }, [[<leader>J]], [[<cmd>Marks! ]] .. table.concat(AZT, " ") .. [[<cr>]])
end

vim.keymap.set({ "n" }, [[<leader>f]], [[<cmd>Files!<cr>]])

vim.keymap.set({ "n" }, [[<leader>g]], [[<cmd>GFiles!?<cr>]])
vim.keymap.set({ "n" }, [[<leader>G]], [[<cmd>GFiles!<cr>]])

vim.keymap.set({ "n" }, [[<leader>/]], [[<cmd>BL!<cr>]])
vim.keymap.set({ "n" }, [[<leader>?]], [[<cmd>RG!<cr>]])

do
  local rg_args = table.concat({
    "",
    "--fixed-strings",
    "--with-filename",
    "--column",
    "--line-number",
    "--no-heading",
    "--color=always",
    "--smart-case",
    "--",
  }, " ")

  vim.api.nvim_create_user_command("RG", function(opts)
    local preview = vim.fn["fzf#vim#with_preview"]()

    vim.fn["fzf#vim#grep2"]([[rg ]] .. rg_args, opts.args, preview, opts.bang)
  end, {
    force = true,
    bang = true,
    nargs = "*",
  })

  vim.api.nvim_create_user_command("BL", function(opts)
    local absname = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(absname) == 0 then
      vim.cmd([[BLines! ]] .. opts.args)
      return
    end

    local relname = vim.fn.fnamemodify(absname, [[:~:.]])
    local name = vim.fn.shellescape(relname)

    local cmd = [[rgb.sh ]] .. name .. rg_args
    local preview = {
      options = { [[--preview=bat --force-colorization --highlight-line {2} -- {1}]] },
    }

    vim.fn["fzf#vim#grep2"](cmd, opts.args, preview, opts.bang)
  end, {
    force = true,
    bang = true,
    nargs = "*",
  })
end
